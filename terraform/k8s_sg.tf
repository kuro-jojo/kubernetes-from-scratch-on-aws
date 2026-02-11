
resource "aws_security_group" "tf_k8s_sg" {
  name        = "k8s-cluster-sg"
  description = "Shared security group for K8s Control Plane and Workers"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "k8s-cluster-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_from_nat" {
  count = var.enable_ssh_rules ? 1 : 0

  security_group_id            = aws_security_group.tf_k8s_sg.id
  referenced_security_group_id = aws_security_group.tf_nat_sg.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  description                  = "Allow SSH hop from NAT instance"
}

# This allows nodes within this SG to talk to each other on all ports.
# This covers etcd (2379), kubelet (10250), and scheduler ports.
resource "aws_vpc_security_group_ingress_rule" "allow_internal_all" {
  security_group_id            = aws_security_group.tf_k8s_sg.id
  referenced_security_group_id = aws_security_group.tf_k8s_sg.id
  ip_protocol                  = "-1"
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

resource "aws_vpc_security_group_egress_rule" "allow_kube_outbound" {
  security_group_id = aws_security_group.tf_k8s_sg.id
  referenced_security_group_id = aws_security_group.tf_k8s_sg.id
  from_port         = 6443
  to_port           = 6443
  ip_protocol       = "tcp"
}