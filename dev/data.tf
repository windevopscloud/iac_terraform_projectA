# If you can access the remote state of the VPC repo
data "terraform_remote_state" "bootstrap" {
  backend = "s3" # or whatever backend they use
  config = {
    bucket = var.state_bucket_name
    key    = var.state_table_name
    region = var.aws_region
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