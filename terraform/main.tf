provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn     = "arn:aws:iam::728432388678:role/TerraformAdminRole"
    session_name = "TerraformSession"
  }
}