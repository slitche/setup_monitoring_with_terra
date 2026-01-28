

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  # default     = "us-east-1"
}

variable "ami" {
  description = "AMI | us-east-1 UBUNTU"
  type        = string
  # default     = "ami-0ecb62995f68bb549"
}

variable "instance_type" {
  description = "Instance type for EC2 instances"
  type        = string
  # default     = "t3.micro"
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
}

variable "ssh_private_key" {
  description = "SSH private key for EC2 instance access. defined in GitHub Secrets"
  type        = string
}