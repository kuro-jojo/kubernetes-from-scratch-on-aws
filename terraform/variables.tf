variable "nat_ami" {
  default = "ami-06c30b4ea8f55d2fd"
}

variable "k8s_instance_type" {
  default = "t2.medium"
}

variable "nat_instance_type" {
  default = "t2.micro"
}

variable "my_ip_cidr" {
  description = "User pi CIDR overriden in a tfvars or in command line"
}