terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "edj-personal"

    workspaces {
      name = "infra"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.34.0"
    }
  }
}

provider "aws" {
  region     = "eu-central-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

provider "aws" {
  region     = "us-east-1"
  alias      = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

