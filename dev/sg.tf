resource "aws_security_group" "github_runner" {
  name_prefix = "github-runner-sg-"
  vpc_id      = data.terraform_remote_state.bootstrap.outputs.vpc_id[0].id

  # Outbound to GitHub (HTTPS for API and actions download)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound to GitHub (HTTP for actions download - fallback)
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound for NTP
  egress {
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all internal VPC traffic
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow SSM traffic to VPC endpoints
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # Only allow to VPC endpoints
  }

  tags = {
    Name = "github-runner-sg"
  }
}

resource "aws_security_group" "vpc_endpoint" {
  name_prefix = "vpc-endpoint-sg-"
  vpc_id      = data.terraform_remote_state.bootstrap.outputs.vpc_id[0].id

  # Allow HTTPS from private subnets
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow outbound to any (endpoints need to communicate with AWS services)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc-endpoint-sg"
  }
}