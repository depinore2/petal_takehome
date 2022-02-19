terraform {
    backend "s3" {
        key = "__terraform-state"
    }
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
}
provider "aws" {
    region = var.region
}

variable "region" { type = string }
