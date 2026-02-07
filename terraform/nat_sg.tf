
resource "aws_security_group" "tf_nat_sg" {
  name        = "tf_nat_sg"
  description = "Allow HTTP/HTTPS & SSH inbound traffic and outbound traffic"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "tf_nat_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "tf_nat_sg_ssh" {
  security_group_id = aws_security_group.tf_nat_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "tf_nat_sg_https" {
  security_group_id = aws_security_group.tf_nat_sg.id
  cidr_ipv4         = module.vpc.private_subnets_cidr_blocks[0]
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "tf_nat_sg_http" {
  security_group_id = aws_security_group.tf_nat_sg.id
  cidr_ipv4         = module.vpc.private_subnets_cidr_blocks[0]
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "tf_nat_sg_outbound_https" {
  security_group_id = aws_security_group.tf_nat_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "tf_nat_sg_outbound_http" {
  security_group_id = aws_security_group.tf_nat_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "tf_nat_sg_outbound_ssh" {
  security_group_id = aws_security_group.tf_nat_sg.id
  cidr_ipv4         = module.vpc.private_subnets_cidr_blocks[0]
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "nat_to_private_k8s" {
  security_group_id = aws_security_group.tf_nat_sg.id
  cidr_ipv4         = module.vpc.private_subnets_cidr_blocks[0]
  from_port         = 6443
  ip_protocol       = "tcp"
  to_port           = 6443
}