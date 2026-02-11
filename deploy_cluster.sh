#!/bin/bash

set -e

WORKDIR=$(pwd -P)

if [[ -z "$WORKDIR" ]]; then
    echo "The workdir cannot be empty"
    exit 1
fi

echo "===== Working from "$WORKDIR" ====="


echo "===== Checking for tailscale auth key ====="

if [[ -z "$TAILSCALE_AUTH_KEY" && -z "$1" ]]; then
    echo "Please either set the TAILSCALE_AUTH_KEY environnment variable or pass the auth key as an argument to the script"
    echo "Usage: "$0" tskey-auth-xxxxxx"
    exit 1
elif [[ "$TAILSCALE_AUTH_KEY" ]]; then
    tailscale_auth_key="$TAILSCALE_AUTH_KEY"
else 
    tailscale_auth_key="$1"
fi

NAT_INSTANCE_USERNAME="ec2-user"
K8S_NODES_INSTANCES_USERNAME="ubuntu"

TERRAFORM_NAT_PUBLIC_IP_OUTPUT_NAME="nat_public_ip"
TERRAFORM_CONTROL_PLANE_IP_OUTPUT_NAME="control_plane_ip"
TERRAFORM_WORKER_NODE_IP_OUTPUT_NAME="worker_node_ip"
TERRAFORM_ENABLE_SSH_RULES_OUTPUT_NAME="enable_ssh_rules"
TERRAFORM_DIR="$WORKDIR"/terraform

mkdir -p "$TERRAFORM_DIR"

ANSIBLE_DIR="$WORKDIR"/ansible
ANSIBLE_INVENTORY="$ANSIBLE_DIR"/inventory.ini
ANSIBLE_CONFIG="$ANSIBLE_DIR"/ansible.cfg
VENV_ACTIVATE_FILE="$ANSIBLE_DIR/venv/bin/activate"

mkdir -p "$ANSIBLE_DIR"


SSH_DIR="$WORKDIR"/ssh

mkdir -p "$SSH_DIR"

SSH_KEY_PATH="$SSH_DIR"/k8s-key
SSH_CONFIG_PATH="$SSH_DIR"/ssh.config

check_terraform_state() {
    return $(terraform -chdir="$TERRAFORM_DIR" show -json | jq '.values.root_module.resources | length // 0')
}

clean_terraform_and_ansible_resources() {
    if [[ check_terraform_state != 0 ]]; then
        logout_nodes_from_tailscale
        if [[ -f $SSH_CONFIG_PATH ]]; then
            echo -e "\n**** Removing ssh config files ****"
            rm $SSH_CONFIG_PATH
        fi
        
        if [[ -f $ANSIBLE_INVENTORY ]]; then
            echo -e "\n**** Removing ansible inventory ****"
            rm $ANSIBLE_INVENTORY
        fi
        echo -e "\n**** Running terraform destroy ****"
        terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve 

        echo "======== Successfully clean up terraform resources ========"
    else
        echo "Error: No resources found in state. Skipping terraform destroy."
    fi
}

logout_nodes_from_tailscale() {
    cd "$ANSIBLE_DIR"
    if [[ -f $VENV_ACTIVATE_FILE ]]; then
        source $VENV_ACTIVATE_FILE
    fi 

    if [[ ! ( -f $ANSIBLE_INVENTORY && -f $SSH_CONFIG_PATH) ]]; then
        echo -e "\nWarning: Skipping tailscale logout because ansible config files were not found."
    else 
        echo -e "\n===== Disconnect nodes from tailscale ======"
        ansible-playbook -i inventory.ini tailscale_down.yml
    fi
    cd "$WORKDIR"
}

wait_for_tailscale() {
    local expected_nodes=("$@")
    echo "Checking Tailscale status for ${#expected_nodes[@]} nodes..."

    while true; do
        local all_online=true
        # Get current tailscale status once per loop
        local status_output=$(tailscale status --active=false)

        for ip in "${expected_nodes[@]}"; do
            # Convert 10.0.1.5 to ip-10-0-1-5 (standard AWS hostname)
            local hostname="ip-${ip//./-}"
            
            # Check if this hostname is in the status and NOT 'offline'
            if ! echo "$status_output" | grep -q "$hostname"; then
                echo "Waiting for $hostname to join tailnet..."
                all_online=false
                break
            fi
        done

        if [ "$all_online" = true ]; then
            echo "All nodes are online in Tailscale!"
            break
        fi
        sleep 3
    done
}

read -n 1 -p "Nuke everything ? (y/N) : " confirm

if [[ "$confirm"  == "y" || "$confirm" == "Y" ]]; then
    clean_terraform_and_ansible_resources
    exit 1
fi

echo -e "\n====== Generating ssh keys to ======"

if [[ ! -f "$SSH_KEY_PATH" ]]; then
    ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -P ""
else 
    echo "Using already existing ssh key"
fi


echo -e "\n====== RUNNING terraform ======"

read -n 1 -p "Clean resources beforehand? : (y/N)" confirm

if [[ "$confirm"  == "y" || "$confirm" == "Y" ]]; then
    clean_terraform_and_ansible_resources
fi

echo -e "\n**** Running terraform apply ****"

enable_ssh_rules=$(terraform -chdir="$TERRAFORM_DIR" output -json | jq -r ".${TERRAFORM_ENABLE_SSH_RULES_OUTPUT_NAME}.value" || true)
if [[ $enable_ssh_rules != "false" ]]; then 
    enable_ssh_rules=true
fi

terraform -chdir="$TERRAFORM_DIR" apply -var="enable_ssh_rules=$enable_ssh_rules" -auto-approve 

get_nodes_ips() {
    nat_public_ip=$(terraform -chdir="$TERRAFORM_DIR" output -json | jq -r ".${TERRAFORM_NAT_PUBLIC_IP_OUTPUT_NAME}.value" | { grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' || :; })
    control_plane_ip=$(terraform -chdir="$TERRAFORM_DIR" output -json | jq -r ".${TERRAFORM_CONTROL_PLANE_IP_OUTPUT_NAME}.value" | { grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' || :; })
    worker_node_ip=$(terraform -chdir="$TERRAFORM_DIR" output -json | jq -r ".${TERRAFORM_WORKER_NODE_IP_OUTPUT_NAME}.value" | { grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' || :; })
}

retry=2

while [[ $retry -gt 0 ]] && ([[ -z "$nat_public_ip" ]] || [[ -z "$control_plane_ip" ]] || [[ -z "$worker_node_ip" ]]); do
    echo -e "\n**** Retrieving NAT, Control Plane and Worker nodes IPs ****"
    get_nodes_ips
    ((retry--))
    sleep 2
done

if [[ $retry == 0 ]]; then
    if [[ -z "$nat_public_ip" ]]; then
        echo "Error: Could not retrieve a valid IPv4 address for $TERRAFORM_NAT_PUBLIC_IP_OUTPUT_NAME"
    fi
    if [[ -z "$control_plane_ip" ]]; then
        echo "Error: Could not retrieve a valid IPv4 address for $TERRAFORM_CONTROL_PLANE_IP_OUTPUT_NAME"
    fi
    if [[ -z "$worker_node_ip" ]]; then
        echo "Error: Could not retrieve a valid IPv4 address for $TERRAFORM_WORKER_NODE_IP_OUTPUT_NAME"
    fi
    
    exit 1
fi 
echo -e "\n**** NAT, Control Plane and Worker nodes IPs retrieved successfully ****"


if [[ $enable_ssh_rules == true ]]; then
    private_nodes="${control_plane_ip%.*}.*"

    echo "====== Generating ansible configuration files ======"

    tee "$SSH_CONFIG_PATH" &>/dev/null <<EOF
# The NAT/Bastion (The only one with a Public IP)
Host nat-bastion
    HostName $nat_public_ip
    User $NAT_INSTANCE_USERNAME
    IdentityFile $SSH_KEY_PATH
    StrictHostKeyChecking no

# The Private Nodes (Using their Private IPs)
Host $private_nodes
    ProxyJump nat-bastion
    User $K8S_NODES_INSTANCES_USERNAME
    IdentityFile $SSH_KEY_PATH
    StrictHostKeyChecking no

Host *
    User ubuntu
    IdentityFile /home/jonathan/projects/kubernetes-from-scratch-on-aws/ssh/k8s-key
    StrictHostKeyChecking no
EOF

    tee "$ANSIBLE_INVENTORY" &>/dev/null <<EOF
[control_plane]
cp-node ansible_host=$control_plane_ip

[workers]
worker-1 ansible_host=$worker_node_ip

[k8s_cluster:children]
control_plane
workers

[k8s_cluster:vars]
default_user=ubuntu
tailscale_auth_key=$tailscale_auth_key
EOF

fi

echo -e "\n===== Configure the cluster by running the ansible playbooks ======"

cd "$ANSIBLE_DIR"
source venv/bin/activate

ansible-playbook -i inventory.ini main.yml


if [[ $enable_ssh_rules == true ]]; then
    echo -e "\n===== Closing NAT SSH holes ======"
    cd $TERRAFORM_DIR
    PRIVATE_IPS=($(terraform output -json private_ips | jq -r '.[]'))
    wait_for_tailscale "${PRIVATE_IPS[@]}"

    echo -e "\n**** Trying to retrieve tailscale ips ****"

    control_plane_tailscale_ip=$(ssh -o ConnectTimeout=60 -F $SSH_CONFIG_PATH ${control_plane_ip} "tailscale ip -4 || :;" || :;)
    worker_node_tailscale_ip=$(ssh -o ConnectTimeout=60 -F $SSH_CONFIG_PATH ${worker_node_ip} "tailscale ip -4 || :;" || :;)

    
    echo "Secure connection verified. Closing NAT SSH holes..."
    terraform -chdir="$TERRAFORM_DIR" apply -var="enable_ssh_rules=false" -auto-approve
    
    if [[ $control_plane_tailscale_ip && $worker_node_tailscale_ip ]]; then
        echo "Using tailscale ips"
        sed -i "s/$control_plane_ip/$control_plane_tailscale_ip/g" $ANSIBLE_INVENTORY
        sed -i "s/$worker_node_ip/$worker_node_tailscale_ip/g" $ANSIBLE_INVENTORY
    fi
fi