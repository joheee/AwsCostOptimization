# Backup bucket. Waste when the lifecycle rule is off: objects stay in
# Standard forever.
resource "aws_s3_bucket" "backups" {
  bucket_prefix = "${var.name_prefix}-backups-"
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  count  = var.enable_s3_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "tier-and-expire"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 90
    }
  }
}

# Waste when retention is 0: logs never expire.
resource "aws_cloudwatch_log_group" "app" {
  name              = "/${var.name_prefix}/app"
  retention_in_days = var.log_retention_days == 0 ? null : var.log_retention_days
}
