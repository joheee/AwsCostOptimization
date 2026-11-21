variable "aws_region" {
  description = "Only ap-southeast-2 is allowed by the org SCP."
  type        = string
  default     = "ap-southeast-2"
}

variable "project" {
  type    = string
  default = "aws-cost-case"
}

variable "environment" {
  description = "before or after. Set in the tfvars file."
  type        = string
}

# --- Web server ---

variable "web_instance_type" {
  type = string
}

variable "web_arch" {
  description = "AMI architecture: x86_64 or arm64. Must match web_instance_type."
  type        = string
  validation {
    condition     = contains(["x86_64", "arm64"], var.web_arch)
    error_message = "web_arch must be x86_64 or arm64."
  }
}

variable "web_volume_gb" {
  type = number
}

variable "web_volume_type" {
  description = "gp2 or gp3."
  type        = string
}

# --- Database ---

variable "db_instance_class" {
  type = string
}

variable "db_multi_az" {
  type = bool
}

variable "db_storage_gb" {
  type = number
}

variable "db_storage_type" {
  description = "gp2 or gp3."
  type        = string
}

# --- Waste toggles ---

variable "enable_nat_gateway" {
  description = "A NAT gateway nothing routes through."
  type        = bool
}

variable "enable_elastic_ip" {
  description = "An Elastic IP attached to nothing."
  type        = bool
}

variable "unattached_volume_gb" {
  description = "Size of the unattached gp2 volume. 0 means none."
  type        = number
}

variable "log_retention_days" {
  description = "CloudWatch log retention. 0 means never expire."
  type        = number
}

variable "enable_s3_lifecycle" {
  description = "Standard-IA after 30 days, expire after 90."
  type        = bool
}

# --- Office-hours schedule ---

variable "enable_schedule" {
  type = bool
}

variable "schedule_timezone" {
  type    = string
  default = "Asia/Jakarta"
}

variable "schedule_stop_cron" {
  description = "EventBridge Scheduler cron. Shift it a few minutes ahead to test."
  type        = string
  default     = "cron(0 19 ? * MON-FRI *)"
}

variable "schedule_start_cron" {
  type    = string
  default = "cron(0 8 ? * MON-FRI *)"
}
