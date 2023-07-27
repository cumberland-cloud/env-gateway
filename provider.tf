terraform {
    backend "s3" {
        bucket          = "cumberland-cloud-gateway-terraform-state"
        dynamodb_table  = "cumberland-cloud-gateway-terraform-lock"
        encrypted       = true
        key             = "terraform.tfstate"
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
    default_tags        = {
        Project         = "Cumberland Cloud"
        Environment     = "Gateway"
        Owner           = "Grant Moore"
        Contact         = "chinchalinchin@gmail.com"
    }
}