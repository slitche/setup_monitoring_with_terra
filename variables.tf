

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "ami" {
  description = "AMI | us-east-1 UBUNTU"
  type        = string
  default     = "ami-0ecb62995f68bb549"
}

variable "instance-type" {
  description = "Instance type for EC2 instances"
  type        = string
  default     = "t3.micro"
}

# variable "prometheus_private_ip" {
#   description = "Prometheus' private_ip"
#   type        = string
#   default     = "10.0.1.50"
# }

