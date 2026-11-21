variable "name_prefix" {
  type = string
}

variable "enable_nat_gateway" {
  description = "A NAT gateway nothing routes through."
  type        = bool
}
