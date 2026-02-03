
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "k8s-from-terraform"
  cidr = "11.0.0.0/16"

  azs             = ["us-east-1a"]
  private_subnets = ["11.0.1.0/24"]
  public_subnets  = ["11.0.101.0/24"]

  create_igw = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Mandatory to tell the vpc to route outbound traffic through the NAT instance
resource "aws_route" "private_nat_route" {
  route_table_id         = module.vpc.private_route_table_ids[0]
  destination_cidr_block = "0.0.0.0/0"

  network_interface_id = aws_instance.tf_k8s_nat.primary_network_interface_id
}

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