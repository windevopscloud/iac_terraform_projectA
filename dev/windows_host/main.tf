data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base"
}

resource "random_password" "admin" {
  length           = 20
  special          = true
  override_special = "!#%*"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 1
}

resource "aws_ssm_parameter" "admin_password" {
  name  = "/${var.environment}/windows/admin-password"
  type  = "SecureString"
  value = random_password.admin.result
}

resource "aws_iam_role" "this" {
  name = "${var.environment}-windows-host"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.environment}-windows-host"
  role = aws_iam_role.this.name
}

resource "aws_instance" "this" {
  ami                    = nonsensitive(data.aws_ssm_parameter.ami.value)
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]
  iam_instance_profile   = aws_iam_instance_profile.this.name
  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }
  user_data                   = "<powershell>net user Administrator '${random_password.admin.result}'</powershell>"
  user_data_replace_on_change = false
  tags                        = { Name = "${var.environment}-windows-host" }
}

output "instance_id" { value = aws_instance.this.id }