

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  # default     = "us-east-1"
  # value will be injected from GitHub Actions secrets
}

variable "ami" {
  description = "AMI | us-east-1 UBUNTU"
  type        = string
  # default     = "ami-0ecb62995f68bb549"
  # value will be injected from GitHub Actions secrets
}

variable "instance_type" {
  description = "Instance type for EC2 instances"
  type        = string
  # default     = "t3.micro"
  # value will be injected from GitHub Actions secrets
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
  # default     = "vpc-0b1a89f0204ae0513"
  # value will be injected from GitHub Actions secrets
}
