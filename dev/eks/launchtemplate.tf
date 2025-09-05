# -----------------------------
# Launch Template for Node Group
# -----------------------------
resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "${var.eks_cluster_name}-lt"
  image_id      = data.aws_ssm_parameter.eks_ami.value
  instance_type = var.lt_min_sizevar.lt_instance_types[0]
  key_name      = var.lt_key_name # Add if you need SSH access

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.eks_nodes_sg.id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.lt_disk_size
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              /etc/eks/bootstrap.sh ${var.eks_cluster_name} \
                --apiserver-endpoint ${aws_eks_cluster.this.endpoint} \
                --b64-cluster-ca ${aws_eks_cluster.this.certificate_authority[0].data} \
                --kubelet-extra-args "--node-labels=eks.amazonaws.com/nodegroup=${var.eks_cluster_name}-nodegroup"
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.eks_cluster_name}-node" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { Name = "${var.eks_cluster_name}-node-volume" })
  }

  lifecycle {
    create_before_destroy = true
  }
}