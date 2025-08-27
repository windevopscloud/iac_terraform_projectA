#!/bin/bash

# Update system
apt-get update -y
apt-get upgrade -y

# Install dependencies
apt-get install -y \
    curl \
    jq \
    unzip \
    docker.io \
    git \
    gnupg \
    software-properties-common \
    apt-transport-https \
    ca-certificates

# Add user to docker group
usermod -aG docker ubuntu

# Install Terraform
curl -o terraform.zip -L "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip"
unzip terraform.zip
mv terraform /usr/local/bin/
rm terraform.zip

# Install specific Helm version
curl -O "https://get.helm.sh/helm-v${helm_version}-linux-amd64.tar.gz"
tar -zxvf "helm-v${helm_version}-linux-amd64.tar.gz"
mv linux-amd64/helm /usr/local/bin/helm
rm -rf linux-amd64 "helm-v${helm_version}-linux-amd64.tar.gz"

# Install specific kubectl version
curl -LO "https://dl.k8s.io/release/v${kubectl_version}/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws/

# Install Node.js (for various CI/CD tools)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install Python and pip
apt-get install -y python3 python3-pip

# Install common Python packages
pip3 install awscli boto3

# Create runner directory
mkdir -p /opt/actions-runner && cd /opt/actions-runner

# Download the latest runner package
runner_version=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/' | head -1)
curl -o actions-runner-linux-x64-${runner_version}.tar.gz -L https://github.com/actions/runner/releases/download/v${runner_version}/actions-runner-linux-x64-${runner_version}.tar.gz

# Extract the installer
tar xzf ./actions-runner-linux-x64-${runner_version}.tar.gz

# Retrieve GitHub token from AWS SSM Parameter Store
echo "Retrieving GitHub token from SSM Parameter Store..."
GITHUB_TOKEN=$(aws ssm get-parameter \
  --name "/github-runner/your-org/your-repo/token" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text)

# Check if token was retrieved successfully
if [ -z "$GITHUB_TOKEN" ] || [ "$GITHUB_TOKEN" == "None" ]; then
  echo "ERROR: Failed to retrieve GitHub token from SSM Parameter Store"
  exit 1
fi

# Create the runner and start the configuration experience
#./config.sh --unattended \
#    --url "https://github.com/${github_org}" \
#    --token "$${GITHUB_TOKEN}" \
#    --name "${runner_name}" \
#    --labels "${labels}" \
#    --replace

# For repository-level runner:
./config.sh --unattended \
    --url "https://github.com/${github_repo}" \
    --token "$${GITHUB_TOKEN}" \
    --name "${runner_name}" \
    --labels "${labels}" \
    --replace

# Install and start service
./svc.sh install
./svc.sh start

# Install AWS SSM Agent
curl -s https://raw.githubusercontent.com/aws/amazon-ssm-agent/main/scripts/amazon-linux-ssm-agent-install.sh -o /tmp/ssm-install.sh
chmod +x /tmp/ssm-install.sh
/tmp/ssm-install.sh

# Start SSM Agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Verify installations
echo "=== Installed Tools ==="
terraform --version
helm version
kubectl version --client
aws --version
node --version
python3 --version

# Clean up
rm actions-runner-linux-x64-${runner_version}.tar.gz
rm /tmp/ssm-install.sh