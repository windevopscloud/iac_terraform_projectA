resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = data.terraform_remote_state.bootstrap.outputs.vpc_id[0].id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = data.terraform_remote_state.bootstrap.outputs.private_subnets[*].id
  security_group_ids = [aws_security_group.vpc_endpoint.id]

  tags = {
    Name = "ssm-vpc-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = data.terraform_remote_state.bootstrap.outputs.vpc_id[0].id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = data.terraform_remote_state.bootstrap.outputs.private_subnets[*].id
  security_group_ids = [aws_security_group.vpc_endpoint.id]

  tags = {
    Name = "ssmmessages-vpc-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = data.terraform_remote_state.bootstrap.outputs.vpc_id[0].id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = data.terraform_remote_state.bootstrap.outputs.private_subnets[*].id
  security_group_ids = [aws_security_group.vpc_endpoint.id]

  tags = {
    Name = "ec2messages-vpc-endpoint"
  }
}