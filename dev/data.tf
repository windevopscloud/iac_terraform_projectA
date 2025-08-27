# If you can access the remote state of the VPC repo
data "terraform_remote_state" "vpc" {
  backend = "s3" # or whatever backend they use
  config = {
    bucket = var.state_bucket_name
    key    = var.state_table_name
    region = var.aws_region
  }
}