variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "At least two, in different AZs."
  type        = list(string)
}

variable "web_security_group_id" {
  description = "The only source allowed to reach PostgreSQL."
  type        = string
}

variable "instance_class" {
  type = string
}

variable "multi_az" {
  type = bool
}

variable "storage_gb" {
  type = number
}

variable "storage_type" {
  description = "gp2 or gp3."
  type        = string
}
