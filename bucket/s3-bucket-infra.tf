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

# add a policy that allows load balancer logs to be stored in the bucket
resource "aws_s3_bucket_policy" "logs_policy" {
  bucket = aws_s3_bucket.s3_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::127311923021:root"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::foo-bucket-s3895662-s4077402/alb/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    }
  ]
}
POLICY
}