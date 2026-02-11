variable "nat_ami" {
  default = "ami-06c30b4ea8f55d2fd"
}

variable "k8s_instance_type" {
  default = "t2.medium"
}

variable "nat_instance_type" {
  default = "t2.micro"
}

variable "enable_ssh_rules" {
  type        = bool
  default     = true
  description = "Use to remove Security group rule that allows ssh into the private subnet"
}