terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
# Região padrão
provider "aws" {
  region = "us-west-2"
}

provider "aws" {
  alias  = "west"
  region = "us-west-1"
}