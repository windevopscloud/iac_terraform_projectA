# -----------------------------
# Launch Template for Node Group
# -----------------------------
resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "${var.cluster_name}-lt"
  image_id      = data.aws_ssm_parameter.eks_ami.value
  instance_type = var.instance_types[0]
  key_name      = var.key_name # Add if you need SSH access

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.eks_nodes_sg.id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.disk_size
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.cluster_name}-node" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { Name = "${var.cluster_name}-node-volume" })
  }

  lifecycle {
    create_before_destroy = true
  }
}