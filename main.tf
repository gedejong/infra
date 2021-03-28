terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "edj-personal"

    workspaces {
      name = "infra"
    }
  }
}

variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.34.0"
    }
  }
}

provider "aws" {
  region                  = "eu-central-1"
  shared_credentials_file = "~/.aws/credentials"
  access_key = var.access_key
  secret_key = var.secret_key
}

module "aws_static_website" {
  source = "github.com/gedejong/terraform-aws-static-website"

  website-domain-main     = "dejongsoftwareengineering.nl"
  website-domain-redirect = "www.dejongsoftwareengineering.nl"
}
