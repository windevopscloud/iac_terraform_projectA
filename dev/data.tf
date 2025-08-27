data "terraform_remote_state" "bootstrap" {
  backend = "s3"

  config = {
    bucket = "windevopscloud-terraform-bucket"
    key    = "bootstrap/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_vpc" "selected" {
  id = data.terraform_remote_state.bootstrap.outputs.vpc_id
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}