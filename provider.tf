terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  # AWS CLI credentials'ını otomatik kullanır.
  # ~/.aws/credentials dosyanın ayarlı olduğundan emin ol.
}
