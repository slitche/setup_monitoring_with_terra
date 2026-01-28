terraform {
  required_version = ">= 1.6.0"

  #   backend "s3" {
  #     bucket         = "my-terraform-state-bucket"
  #     key            = "ec2-instance/terraform.tfstate"
  #     region         = "us-east-1"
  #     dynamodb_table = "terraform-locks"
  #     encrypt        = true
  #   }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Get your current public IP
data "http" "myip" {
  url = "https://checkip.amazonaws.com/"
}
