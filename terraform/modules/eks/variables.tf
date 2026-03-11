variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "environment" {
  type = string
}

variable "bastion_sg_id" {
  description = "Security group of bastion host"
  type        = string
}