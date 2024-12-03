variable "environment_name" {
  description = "The environment name"
  type        = string
  default     = "dev"
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket to store the Terraform state file"
  type        = string
  default     = "sandbox-tf-test"
}

//variable "dynamodb_state_lock_table_name" {
  //description = "The name of the DynamoDB table for state locking"
  //type        = string
  //default     = "terraform-state-lock"
//}

variable "aws_region" {
  description = "The AWS region to use"
  type        = string
  default     = "us-east-1"
}

variable "state_key" {
  description = "The path within the S3 bucket where the state file will be stored"
  type        = string
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  type        = string
}
