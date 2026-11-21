variable "name_prefix" {
  type = string
}

variable "environment" {
  description = "Shown on the demo page."
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "arch" {
  description = "AMI architecture: x86_64 or arm64. Must match instance_type."
  type        = string
  validation {
    condition     = contains(["x86_64", "arm64"], var.arch)
    error_message = "arch must be x86_64 or arm64."
  }
}

variable "volume_gb" {
  type = number
}

variable "volume_type" {
  description = "gp2 or gp3."
  type        = string
}

variable "enable_elastic_ip" {
  description = "An Elastic IP attached to nothing."
  type        = bool
}

variable "unattached_volume_gb" {
  description = "Size of the unattached gp2 volume. 0 means none."
  type        = number
}
