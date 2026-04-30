terraform {
  # S3 bucket for state storage with DynamoDB locking for consistency
  backend "s3" {
    bucket         = "value"
    key            = "dev/terraform.tfstate"
    region         = "value"
    dynamodb_table = "value"
    encrypt        = true
  }
}
