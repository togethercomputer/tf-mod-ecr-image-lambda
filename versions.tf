terraform {
  required_version = ">=1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.64.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}
