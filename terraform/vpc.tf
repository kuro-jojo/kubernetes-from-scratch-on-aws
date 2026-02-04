
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