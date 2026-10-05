terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.81"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4"
    }
  }

  # backend "s3" {
  #   bucket       = "my-terraform-state"
  #   key          = "examples/complete/terraform.tfstate"
  #   region       = "us-east-1"
  #   use_lockfile = true
  #   encrypt      = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
