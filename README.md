# Kubernetes From Scratch on AWS

This repository is an exploratory, educational project that documents and automates the steps required to bootstrap a small Kubernetes cluster on AWS EC2 using `kubeadm`.

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

## Remaining work / Known limitations

- Defining and hardening external user access (how external users securely reach the cluster API and kubeconfigs).

## Quick start (experiment / local use)

1. Ensure you have an AWS account and credentials with the required permissions for Terraform to create VPCs, Security Groups, and EC2 instances.

2. Run the repository's final automation flow (Terraform + Ansible or the orchestration wrapper) : do not run the legacy `scripts/` helpers used during initial manual experiments. Example options:

```bash
./deploy_cluster.sh
```

Notes:
- The `scripts/` folder contains older manual helpers and should not be used for the final automated flow.
- This deployment is for experimental and learning environments; follow hardening steps before running production workloads.

## Next steps I intend to work on

- Finish Terraform automation for a repeatable infra provisioning pipeline.
- Implement secure external access to the cluster API (e.g., via a bastion or load balancer).
...