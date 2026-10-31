
variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ssh_allowed_cidr" {
  description = "Approved CIDR range for SSH access"
  type        = string
  default     = "203.0.113.10/32"

  validation {
    condition     = can(cidrnetmask(var.ssh_allowed_cidr))
    error_message = "Provide a valid IPv4 CIDR range."
  }
}
