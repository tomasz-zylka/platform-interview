terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.67.0"
    }
  }
}

provider "aws" {
  region                  = "eu-central-1"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "default"
}
