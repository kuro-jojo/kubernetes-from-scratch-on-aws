#!/bin/bash

set -e

WORKDIR=$(pwd -P)

if [ -z $WORKDIR ]; then
    echo "Workdir cannot be empty"
    exit 1
fi

echo "===== Working from $WORKDIR ====="


TERRAFORM_NAT_PUBLIC_IP_OUTPUT_NAME="nat_public_ip"
TERRAFORM_CONTROL_PLANE_OUTPUT_NAME="control_plane_ip"
TERRAFORM_WORKER_NODE_OUTPUT_NAME="worker_node_ip"
TERRAFORM_DIR=$WORKDIR/terraform

mkdir -p "$TERRAFORM_DIR"


SSH_DIR=$WORKDIR/ssh

mkdir -p $SSH_DIR

SSH_KEY_PATH=$SSH_DIR/k8s-key
SSH_CONFIG_PATH=$SSH_DIR/ssh.config

ANSIBLE_DIR=$WORKDIR/ansible
ANSIBLE_INVENTORY=$ANSIBLE_DIR/inventory.ini

mkdir -p $ANSIBLE_DIR

echo "====== Generating ssh keys ======"

if [[ ! -f $SSH_KEY_PATH ]]; then
    ssh-keygen -t ed25519 -f $SSH_KEY_PATH -P ""
else 
    echo "Using already existing ssh key"
fi


echo "====== RUNNING terraform ======"

read -n 1 -p "Run terraform destroy?: " confirm

if [[ $confirm  == "y" || $confirm == "Y" ]]; then
    echo -e "\nRunning terraform destroy"
    terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve 
fi
echo "Running terraform apply"

terraform -chdir="$TERRAFORM_DIR" apply -auto-approve 

nat_public_ip=$(terraform -chdir="$TERRAFORM_DIR" output | grep $TERRAFORM_NAT_PUBLIC_IP_OUTPUT_NAME | awk '{print $3}')
control_plane_ip=$(terraform -chdir="$TERRAFORM_DIR" output | grep $TERRAFORM_CONTROL_PLANE_OUTPUT_NAME | awk '{print $3}')
worker_node_ip=$(terraform -chdir="$TERRAFORM_DIR" output | grep $TERRAFORM_WORKER_NODE_OUTPUT_NAME | awk '{print $3}')


if [[ -z $nat_public_ip || -z $control_plane_ip || -z $worker_node_ip ]]; then
    echo "Nat, CP, and WN ips were not found"
    exit 1
fi 

private_nodes="${control_plane_ip%.*}.*\""
NAT_USERNAME="ec2-user"
K8S_INSTANCES_USERNAME="ubuntu"

echo "====== Generating ssh config for ansible ======"

tee $SSH_CONFIG_PATH <<EOF
# The NAT/Bastion (The only one with a Public IP)
Host nat-bastion
    HostName $nat_public_ip
    User $NAT_USERNAME
    IdentityFile $SSH_KEY_PATH
    StrictHostKeyChecking no

# The Private Nodes (Using their Private IPs)
Host $private_nodes
    ProxyJump nat-bastion
    User $K8S_INSTANCES_USERNAME
    IdentityFile $SSH_KEY_PATH
    StrictHostKeyChecking no
EOF

tee $ANSIBLE_INVENTORY <<EOF
[control_plane]
cp-node ansible_host=$control_plane_ip

[workers]
worker-1 ansible_host=$worker_node_ip

[k8s_cluster:children]
control_plane
workers
EOF


echo "===== Testing ansible connection ======"

cd $ANSIBLE_DIR
source venv/bin/activate
ansible k8s_cluster -i inventory.ini -m ping

ansible-playbook -i inventory.ini prepare_nodes.yml