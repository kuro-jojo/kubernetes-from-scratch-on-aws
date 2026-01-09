# K8s From Scratch: AWS Exploration

This repository documents my journey of deploying a Kubernetes cluster from the ground up on AWS EC2 using `kubeadm`. The goal of this project is to evolve a manual "proof-of-concept" into a hardened, automated, and production-ready environment.

## 🏗 Current Architecture (Phase 1)
The cluster is currently a minimal setup focused on functional validation and understanding the bootstrap process.

* **Infrastructure:** 2x EC2 Instances (Control Plane & Worker Node).
* **OS:** Ubuntu 22.04.
* **Runtime:** Docker Engine with `cri-dockerd`.
* **Networking (CNI):** Flannel (VxLAN).
* **Control Plane:** Single master initialized via `kubeadm`, exposed via Public IP for local `kubectl` access.



---

## 🚀 Setup Steps Included
The scripts in this repository automate:
1.  **System Preparation:** Disabling swap, loading kernel modules (`overlay`, `br_netfilter`), and configuring `sysctl` for bridged traffic.
2.  **Runtime Installation:** Deployment of Docker and the `cri-dockerd` adapter required for Kubernetes 1.24+.
3.  **K8s Tooling:** Installation of `kubelet`, `kubeadm`, and `kubectl`.
4.  **Cluster Initialization:** `kubeadm init` using `--control-plane-endpoint` to allow remote access.
5.  **Identity & RBAC:** Manual generation of user certificates (X.509) and associated `RoleBinding` for restricted access.

---

## ⚠️ Current Limitations
* **Security:** Instances are in Public Subnets; Port 22 (SSH) and 6443 (API) are open to `0.0.0.0/0`.
* **Identity:** Using static certificates (no easy revocation) instead of OIDC.
* **Networking:** Flannel does not support **Network Policies**, meaning there is no isolation between pods.
* **Resiliency:** Single Control Plane node (no High Availability).
* **Deployment:** Manual "ClickOps" used for initial AWS infrastructure.

---

## 🛠 Roadmap

### Phase 2: Hardening (Current Goal)
- [ ] **Private Networking:** Move nodes to private subnets.
- [ ] **Secure Access:** Remove public IPs; use **AWS SSM Session Manager** or **Tailscale** for cluster management.
- [ ] **CRI Migration:** Transition from Docker to **containerd** for a lighter footprint.
- [ ] **Policy Enforcement:** Replace Flannel with **Calico** to implement Pod-to-Pod firewalls.

### Phase 3: Infrastructure as Code (IaC)
- [ ] **Terraform:** Automate VPC, Security Groups, and EC2 provisioning.
- [ ] **Ansible:** Replace manual scripts with idempotent playbooks for node configuration.

### Phase 4: Advanced Identity
- [ ] **OIDC:** Integrate GitHub Actions or Google Workspace for cluster authentication.

---

## 📝 How to Use
> **Warning:** This setup is for educational purposes. Do not run production workloads on this configuration.

1.  Provision two Ubuntu 22.04 instances on AWS.
2.  Execute `scripts/01_prep.sh` on both nodes.
3.  Execute `scripts/02_master.sh` on the Control Plane.
4.  Run the generated `kubeadm join` command on the Worker Node.
5. (Optional) To add a user "kuro" run the `scripts/03_add_user.sh` script
