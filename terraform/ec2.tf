resource "aws_key_pair" "k8s_key" {
  key_name   = "k8s-ssh-key"
  public_key = file("../ssh/k8s-key.pub")
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "tf_k8s_control_plane" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.k8s_instance_type
  subnet_id            = module.vpc.private_subnets[0]
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_access_profile.name

  key_name = aws_key_pair.k8s_key.key_name

  vpc_security_group_ids = [aws_security_group.tf_k8s_sg.id]

  tags = {
    Name = "tf_k8s_control_plane"
  }

}

resource "aws_instance" "tf_k8s_worker_node" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.k8s_instance_type
  subnet_id            = module.vpc.private_subnets[0]
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_access_profile.name

  key_name = aws_key_pair.k8s_key.key_name

  vpc_security_group_ids = [aws_security_group.tf_k8s_sg.id]

  tags = {
    Name = "tf_k8s_worker_node"
  }

}

resource "aws_instance" "tf_k8s_nat" {
  ami           = var.nat_ami
  instance_type = var.nat_instance_type
  subnet_id     = module.vpc.public_subnets[0]

  associate_public_ip_address = true

  key_name = aws_key_pair.k8s_key.key_name

  vpc_security_group_ids = [aws_security_group.tf_nat_sg.id]
  source_dest_check      = false

  tags = {
    Name = "tf_k8s_nat"
  }
}
