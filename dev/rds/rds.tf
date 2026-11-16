resource "aws_db_subnet_group" "this" {
  name       = "signup-db-${var.environment}"
  subnet_ids = data.aws_subnets.isolated.ids      # was var.isolated_subnets
  tags       = var.tags

  lifecycle {
    precondition {
      condition  = length(data.aws_subnets.isolated.ids) >= 2
      error_message = "Need 2 isolated subnets (set create_isolated_subnets = yes in init_aws)."
    }
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "signup-rds-${var.environment}-"
  description = "Postgres from EKS nodes only"
  vpc_id     = data.aws_vpc.selected.id            # was var.vpc_id
  tags        = merge(var.tags, { Name = "signup-rds-sg" })
}

# RDS side: allow nodes in
resource "aws_security_group_rule" "rds_ingress_nodes" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.node_security_group_id
  security_group_id        = aws_security_group.rds.id
  description              = "Postgres from EKS nodes"
}

# Node side: the node SG has restricted egress, so allow out to RDS
resource "aws_security_group_rule" "nodes_egress_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds.id
  security_group_id        = var.node_security_group_id
  description              = "Postgres to RDS"
}

resource "aws_db_instance" "this" {
  identifier        = "signup-${var.environment}"
  engine            = "postgres"
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = var.db_multi_az

  backup_retention_period = var.db_backup_retention_days
  skip_final_snapshot     = true   # poc only
  deletion_protection     = false  # poc only

  tags = var.tags
}