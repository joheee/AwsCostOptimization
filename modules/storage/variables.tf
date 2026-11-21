variable "name_prefix" {
  type = string
}

variable "enable_s3_lifecycle" {
  description = "Standard-IA after 30 days, expire after 90."
  type        = bool
}

variable "log_retention_days" {
  description = "CloudWatch log retention. 0 means never expire."
  type        = number
}
