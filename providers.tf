terraform {
  cloud {
    organization = "s_tc_1"

    workspaces {
      name = "project_lab"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}