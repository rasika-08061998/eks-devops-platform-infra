variable "vpc_id" {
  description = "VPC ID where bastion will run"
  type        = string
}

variable "public_subnet" {
  description = "Public subnet for bastion"
  type        = string
}