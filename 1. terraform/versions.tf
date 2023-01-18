terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "prat-lab"
    key            = "lab-terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "prat-tfstate-lock"
  }

  required_providers {
    aws = {
      source       = "hashicorp/aws"
      version      = ">= 4.47"
    }
  }
}
