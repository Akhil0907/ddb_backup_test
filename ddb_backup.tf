terraform {
  backend "s3" {
    region = "us-east-1"
    bucket = "sandbox-tf-test"
    key = "tfstate/sandbox/devops.tfstate"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.74.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      terraform = true
    }
  }
}

resource "aws_dynamodb_table" "content" {
  name         =  "sandbox"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }
  attribute {
    name = "sk"
    type = "S"
  }
  point_in_time_recovery {
    enabled = true
  }
  lifecycle {
    ignore_changes = [name, replica]
  }
}
