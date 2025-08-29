# ECR API Endpoint (for Docker image management)
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = data.terraform_remote_state.bootstrap.outputs.vpc_vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = data.terraform_remote_state.bootstrap.outputs.vpc_private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = {
    Name = "ecr-api-vpc-endpoint"
  }
}

# ECR DKR Endpoint (for Docker registry operations)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = data.terraform_remote_state.bootstrap.outputs.vpc_vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = data.terraform_remote_state.bootstrap.outputs.vpc_private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = {
    Name = "ecr-dkr-vpc-endpoint"
  }
}

# S3 Gateway Endpoint (for S3 access - no additional cost)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = data.terraform_remote_state.bootstrap.outputs.vpc_vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = data.terraform_remote_state.bootstrap.outputs.vpc_private_route_table_ids

  tags = {
    Name = "s3-vpc-endpoint"
  }
}

# CloudWatch Logs Endpoint (for container logs)
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = data.terraform_remote_state.bootstrap.outputs.vpc_vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = data.terraform_remote_state.bootstrap.outputs.vpc_private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = {
    Name = "logs-vpc-endpoint"
  }
}

# STS Endpoint (for security token service)
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = data.terraform_remote_state.bootstrap.outputs.vpc_vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sts"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = data.terraform_remote_state.bootstrap.outputs.vpc_private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = {
    Name = "sts-vpc-endpoint"
  }
}