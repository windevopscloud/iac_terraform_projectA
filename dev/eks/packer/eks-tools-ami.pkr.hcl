source "amazon-ebs" "eks_tools" {
  region        = var.region
  instance_type = var.instance_type
  ami_name      = "${var.ami_name_prefix}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  ssh_username  = var.ssh_username

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
      "dnf install -y unzip tar gzip git jq curl amazon-ssm-agent telnet bind-utils nmap-ncat docker",

      "systemctl enable amazon-ssm-agent",
      "systemctl start amazon-ssm-agent",
      "systemctl enable docker",
      "systemctl start docker",

      # kubectl
      "curl -o /usr/local/bin/kubectl https://amazon-eks.s3.${var.region}.amazonaws.com/${var.eks_version}/${var.kubectl_date}/bin/linux/amd64/kubectl",
      "chmod +x /usr/local/bin/kubectl",

      # eksctl
      "curl -sL https://github.com/eksctl-io/eksctl/releases/${var.eksctl_version}/download/eksctl_Linux_amd64.tar.gz | tar xz -C /usr/local/bin",

      # helm
      "curl -fsSL https://get.helm.sh/helm-v${var.helm_version}-linux-amd64.tar.gz | tar xz -C /usr/local/bin --strip-components=1 linux-amd64/helm"
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}