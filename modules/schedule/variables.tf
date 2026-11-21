variable "name_prefix" {
  type = string
}

variable "enabled" {
  description = "Create the schedules. Off in before."
  type        = bool
}

variable "timezone" {
  type = string
}

variable "stop_cron" {
  description = "EventBridge Scheduler cron. Shift it a few minutes ahead to test."
  type        = string
}

variable "start_cron" {
  type = string
}

variable "instance_id" {
  type = string
}

variable "instance_arn" {
  type = string
}

variable "db_identifier" {
  type = string
}

variable "db_arn" {
  type = string
}
