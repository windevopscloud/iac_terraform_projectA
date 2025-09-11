# provider.hcl
packer {
  required_plugins {
    amazon = {
      version = ">= 1.4.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "eks_tools" {
  region        = var.region
  instance_type = var.instance_type
  ami_name      = "${var.ami_name_prefix}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  
  # VPC ID - use a single filter
  vpc_filter {
    filters = {
      "tag:Name" = "vpc-*"
    }
  }
  
  # Subnet filter - only one subnet_filter block allowed
  subnet_filter {
    filters = {
      "tag:Name" = "private-1-*"
    }
  }
  
  # Security group filter - only one block allowed, use multiple filters
  security_group_filter {
    filters = {
      "tag:Name" = "github-runner-sg"
    }
  }
  
  # IAM instance profile - does not support filter
  iam_instance_profile = var.iam_instance_profile_name

  source_ami_filter {
    filters = {
      name                = "al2023-ami-*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["137112412989"]
    most_recent = true
  }
  
  ssh_username = var.ssh_username
  communicator = "ssh"
  ssh_timeout  = "5m"
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
