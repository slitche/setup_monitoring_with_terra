terraform {
  required_version = ">= 1.6.0"

    backend "s3" {
      bucket         = vars.tf_s3_bucket
      key            = vars.tf_state_key
      region         = vars.region
      # dynamodb_table = "terraform-locks"
      # encrypt        = true
    }

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
