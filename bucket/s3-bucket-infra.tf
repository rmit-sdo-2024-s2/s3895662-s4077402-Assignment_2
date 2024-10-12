data "aws_caller_identity" "current" {}

# create s3 bucket
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "foo-bucket-s3895662-s4077402" # change the name if it says "still creating..." forever and make sure to change main.tf backend too
  force_destroy = true
}

# enable versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# apply lock to state bucket
resource "aws_dynamodb_table" "s3_bucket_lock" {
  name           = "foostatelock"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}