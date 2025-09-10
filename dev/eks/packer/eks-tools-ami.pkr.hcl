# provider.hcl
packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "eks_tools" {
  region        = var.region
  instance_type = var.instance_type
  ami_name      = "${var.ami_name_prefix}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  
   # Private subnet configuration
  vpc_id {
    filters = {
      "tag:Environment" = var.environment
    }
  }
  
  # Subnet discovery using filters (NO data block)
  subnet_filter {
    filters = {
      "vpc-id"   = self.vpc_id  # Reference discovered VPC
      "tag:Name" = "private-*"
    }
    most_recent = true
  }
  
  # Security Group discovery using filters (NO data block)
  security_group_filter {
    filters = {
      "tag:Name" = "github-runner-sg"
    }
  }
  
  security_group_filter {
    filters = {
      "tag:Name" = "vpc-endpoint-sg-ssm"
    }
  }
  
  # IAM Instance Profile discovery using filters (NO data block)
  iam_instance_profile {
    filters = {
      "name" = "github-runner-profile-*"
    }
  }

  # Use SSM communicator instead of SSH
  #ssh_username  = var.ssh_username
  communicator = "ssm"
  ssh_timeout  = "5m"

  source_ami_filter {
    filters = {
      name                = "al2023-ami-*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["137112412989"] # Amazon Linux 2023 owner
    most_recent = true
  }
}

build {
  name    = "eks-tools"
  sources = ["source.amazon-ebs.eks_tools"]

  provisioner "shell" {
    inline = [
      "set -eux",

      # Install base tools
      "sudo dnf install -y unzip tar gzip git jq amazon-ssm-agent telnet bind-utils nmap-ncat docker",

      "sudo systemctl enable amazon-ssm-agent",
      "sudo systemctl start amazon-ssm-agent",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",

      # kubectl
      "sudo curl -o /usr/local/bin/kubectl https://amazon-eks.s3.${var.region}.amazonaws.com/${var.eks_version}/${var.kubectl_date}/bin/linux/amd64/kubectl",
      "sudo chmod +x /usr/local/bin/kubectl",

      # eksctl
      "sudo curl -sL https://github.com/eksctl-io/eksctl/releases/${var.eksctl_version}/download/eksctl_Linux_amd64.tar.gz | sudo tar xz -C /usr/local/bin",

      # helm
      "sudo curl -fsSL https://get.helm.sh/helm-v${var.helm_version}-linux-amd64.tar.gz | sudo tar xz -C /usr/local/bin --strip-components=1 linux-amd64/helm"
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}
