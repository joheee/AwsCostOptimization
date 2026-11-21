resource "aws_db_subnet_group" "main" {
  name_prefix = "${var.name_prefix}-"
  subnet_ids  = var.subnet_ids
}

# Reachable only from the web server's security group.
resource "aws_security_group" "db" {
  name_prefix = "${var.name_prefix}-db-"
  description = "PostgreSQL from the web server only"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "from_web" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = var.web_security_group_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_db_instance" "main" {
  identifier     = var.name_prefix
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.instance_class
  multi_az       = var.multi_az

  allocated_storage = var.storage_gb
  storage_type      = var.storage_type
  storage_encrypted = true

  db_name  = "app"
  username = "app"
  # The password is generated and stored by RDS in Secrets Manager; it never
  # passes through Terraform.
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  backup_retention_period = 1
  skip_final_snapshot     = true # demo only, destroyed the same day
}
