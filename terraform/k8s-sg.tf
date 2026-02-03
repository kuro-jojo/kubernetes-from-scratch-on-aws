
resource "aws_security_group" "tf_k8s_sg" {
  name        = "k8s-cluster-sg"
  description = "Shared security group for K8s Control Plane and Workers"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "k8s-cluster-sg"
  }
}

# 1. ALLOW NODES TO TALK TO THE API SERVER (Port 6443)
resource "aws_vpc_security_group_ingress_rule" "allow_api_local" {
  security_group_id = aws_security_group.tf_k8s_sg.id
  cidr_ipv4         = var.my_ip_cidr
  from_port         = 6443
  ip_protocol       = "tcp"
  to_port           = 6443
}

# 2. INTERNAL CLUSTER COMMUNICATION (Self-Reference)
# This allows nodes within this SG to talk to each other on all ports.
# This covers etcd (2379), kubelet (10250), and scheduler ports.
resource "aws_vpc_security_group_ingress_rule" "allow_internal_all" {
  security_group_id            = aws_security_group.tf_k8s_sg.id
  referenced_security_group_id = aws_security_group.tf_k8s_sg.id
  ip_protocol                  = "-1"
}

# 3. FLANNEL OVERLAY (VXLAN)
# Specifically required for Flannel pod-to-pod communication
resource "aws_vpc_security_group_ingress_rule" "allow_flannel_vxlan" {
  security_group_id            = aws_security_group.tf_k8s_sg.id
  referenced_security_group_id = aws_security_group.tf_k8s_sg.id
  from_port                    = 8472
  to_port                      = 8472
  ip_protocol                  = "udp"
}

# 4. EGRESS: ALLOW ALL OUTBOUND
# Required for nodes to reach the NAT Gateway / Internet for updates/images
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.tf_k8s_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ALLOW OUTBOUND HTTPS (443) for SSM and Image Pulls
resource "aws_vpc_security_group_egress_rule" "allow_https_outbound" {
  security_group_id = aws_security_group.tf_k8s_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow outbound HTTPS for SSM and Container Images"
}

# ALLOW OUTBOUND HTTP (80) for OS Updates (apt/yum)
resource "aws_vpc_security_group_egress_rule" "allow_http_outbound" {
  security_group_id = aws_security_group.tf_k8s_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow outbound HTTP for apt updates"
}