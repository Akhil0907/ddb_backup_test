provider "aws" {
  region = "us-east-1"
  profile = "akhil-mfa"
}

provider "random" {
  # No configuration needed for the random provider
}

provider "local" {
  # No configuration needed for the local provider
}

resource "random_string" "hash_key" {
  length  = 16
  special = false
}

resource "aws_dynamodb_table" "content" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"  # Partition key
  range_key    = "sk"  # Sort key

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "N"
  }


  point_in_time_recovery {
    enabled = true
  }

  lifecycle {
    ignore_changes = [
      name,
      replica
    ]
  }
}
