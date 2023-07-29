terraform {
    backend "s3" {
        bucket          = "cumberland-cloud-terraform-state"
        dynamodb_table  = "cumberland-cloud-terraform-locks"
        encrypted       = true
        region          = "us-east-1"
    }
    required_providers {
        aws             = {
            source      = "hashicorp/aws"
            version     = "4.8.0"
        }
    }
}

provider "aws" {
    default_tags {
    tags                = {
        Contact         = "chinchalinchin@gmail.com"
        Component       = "Gateway"
        Environment     = "Production"
        Owner           = "Grant Moore"
        Maintainer      = "Grant Moore"
        Project         = "Cumberland Cloud"
    }
  }
}