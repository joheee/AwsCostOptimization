# Office-hours schedule, only when var.enabled is true (off in before).
# EventBridge Scheduler calls the EC2 and RDS APIs directly (universal targets).

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scheduler" {
  count = var.enabled ? 1 : 0

  name_prefix        = "${var.name_prefix}-scheduler-"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

# Least privilege: stop/start on this one instance and this one database.
# No "*" resources.
data "aws_iam_policy_document" "scheduler" {
  statement {
    actions   = ["ec2:StopInstances", "ec2:StartInstances"]
    resources = [var.instance_arn]
  }

  statement {
    actions   = ["rds:StopDBInstance", "rds:StartDBInstance"]
    resources = [var.db_arn]
  }
}

resource "aws_iam_role_policy" "scheduler" {
  count = var.enabled ? 1 : 0

  name   = "stop-start"
  role   = aws_iam_role.scheduler[0].id
  policy = data.aws_iam_policy_document.scheduler.json
}

locals {
  schedules = var.enabled ? {
    ec2-stop = {
      cron   = var.stop_cron
      target = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
      input  = jsonencode({ InstanceIds = [var.instance_id] })
    }
    ec2-start = {
      cron   = var.start_cron
      target = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
      input  = jsonencode({ InstanceIds = [var.instance_id] })
    }
    rds-stop = {
      cron   = var.stop_cron
      target = "arn:aws:scheduler:::aws-sdk:rds:stopDBInstance"
      input  = jsonencode({ DbInstanceIdentifier = var.db_identifier })
    }
    rds-start = {
      cron   = var.start_cron
      target = "arn:aws:scheduler:::aws-sdk:rds:startDBInstance"
      input  = jsonencode({ DbInstanceIdentifier = var.db_identifier })
    }
  } : {}
}

resource "aws_scheduler_schedule" "office_hours" {
  for_each = local.schedules

  name                         = "${var.name_prefix}-${each.key}"
  schedule_expression          = each.value.cron
  schedule_expression_timezone = var.timezone

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = each.value.target
    role_arn = aws_iam_role.scheduler[0].arn
    input    = each.value.input
  }
}
