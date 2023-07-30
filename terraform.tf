terraform {
  required_version      = ">= 1.5.0"

  backend "s3" {
    bucket              = "cumberland-cloud-terraform-state"
    dynamodb_table      = "cumberland-cloud-terraform-locks"
    encrypted           = true
    region              = "us-east-1"
  }

  required_providers {
    aws               = {
      source          = "hashicorp/aws"
      version         = ">= 4.8.0"
    }
  }
}