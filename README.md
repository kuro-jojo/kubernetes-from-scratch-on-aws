# Kubernetes From Scratch on AWS

This repository is an educational project that documents and automates the steps required to bootstrap a small Kubernetes cluster on AWS EC2 using `kubeadm`.

Purpose:
- Capture the manual steps needed to understand cluster bootstrapping.
- Produce reusable scripts and Ansible playbooks to automate those steps.
- Evolve the POC into a more secure, idempotent IaC-based deployment.

## What this repo contains

- `scripts/` : small shell helpers used during early experiments (prep nodes, init master, add user, enable bridge networking).
- `ansible/` : playbooks and roles used to configure nodes and run idempotent steps.
- `terraform/` : basic Terraform files used to provision VPC, security groups, and EC2 machines (work in progress).
 - `deploy_cluster.sh` : orchestration script that provisions infrastructure (Terraform) and deploys the cluster by running the Ansible playbooks.

## Achievements (what's implemented)

 - Terraform configurations to provision VPC, NAT, security groups, and EC2 instances (baseline implemented).
 - Nodes run in private subnets and do not expose SSH : access to instances is done via AWS SSM (no direct SSH). 
 - Ansible playbooks and inventories to configure nodes and run the final cluster setup (provisioning + configuration flow implemented).
- Tailscale is used to provide secure access to the cluster nodes for management and debugging (provisioning flow implemented).


## Requirements

- AWS account and credentials with permissions for Terraform to create VPCs, Security Groups, and EC2 instances.
- `terraform` installed and available in your PATH.
- `ansible` installed and available in your PATH.
- `tailscale` available on the admin/control host for node provisioning and access.
- Tailscale auth key: the deployment scripts expect a Tailscale auth key to provision nodes into your Tailnet. Provide the key as an environment variable named `TAILSCALE_AUTH_KEY` or pass it when invoking `deploy_cluster.sh`.


## Quick start (experiment / local use)

Run the repository's final automation flow (Terraform + Ansible or the orchestration wrapper) — do not run the legacy `scripts/` helpers used during initial manual experiments. 

Example option:


```bash
# export the auth key (recommended)
export TAILSCALE_AUTH_KEY="tskey_your_auth_key_here"
./deploy_cluster.sh

# or pass it inline for a single invocation
TAILSCALE_AUTH_KEY="tskey_your_auth_key_here" ./deploy_cluster.sh

# or directly specify the key in the script call
./deploy_cluster.sh "tskey_your_auth_key_here"
```
Notes:
- The `scripts/` folder contains older manual helpers and should not be used for the final automated flow.
- This deployment is for experimental and learning environments; follow hardening steps before running production workloads.
