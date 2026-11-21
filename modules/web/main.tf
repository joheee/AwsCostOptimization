# AMI lookup pinned by name filter and owner (Amazon). The name pattern fixes
# the Amazon Linux 2023 major line; the architecture follows var.arch.
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-${var.arch}"]
  }

  filter {
    name   = "architecture"
    values = [var.arch]
  }
}

# No SSH: port 80 only.
resource "aws_security_group" "web" {
  name_prefix = "${var.name_prefix}-web-"
  description = "HTTP in, everything out"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP from anywhere (public demo page)"
  cidr_ipv4         = "0.0.0.0/0" # public web page, the only open port
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.web.id
  description       = "Package installs and updates"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.web.id]

  # IMDSv2 only.
  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = var.volume_gb
    volume_type = var.volume_type
    encrypted   = true
  }

  # The page does not need the database.
  user_data = <<-EOT
    #!/bin/bash
    dnf install -y nginx
    echo "aws-cost-case ${var.environment}: ${var.instance_type}" > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  EOT

  tags = { Name = "${var.name_prefix}-web" }
}

# Waste: an Elastic IP attached to nothing.
resource "aws_eip" "idle" {
  count  = var.enable_elastic_ip ? 1 : 0
  domain = "vpc"
}

# Waste: a volume nobody attached. It holds nothing, so no snapshot here;
# in a real account snapshot first, then delete.
resource "aws_ebs_volume" "unattached" {
  count = var.unattached_volume_gb > 0 ? 1 : 0

  availability_zone = aws_instance.web.availability_zone
  size              = var.unattached_volume_gb
  type              = "gp2"
}
