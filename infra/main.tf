terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket = "foo-bucket-s3895662-s4077402"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "foostatelock"
  }
}

provider "aws" {
  region = "us-east-1"
}

# configure Ubuntu machine image
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# identify key pair
resource "aws_key_pair" "admin" {
  key_name   = "foo_ec2_key"
  public_key = file(var.public_key_path)
}

# fetch the host's public ip
data "external" "user_public_ip" {
  program = ["bash", "-c", "echo '{\"ip\": \"'$(curl -s http://checkip.amazonaws.com)'\"}'"]
}

resource "aws_security_group" "app_security_group" {
  name = "app_security_group"

  # SSH inbound
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.external.user_public_ip.result.ip}/32"] # secure port 22 with the public ip of the host
  }

  # HTTP inbound
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL outbound
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS outbound
  egress {
    from_port   = 0
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_security_group" {
  name = "db_security_group"

  # PostgreSQL inbound
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.app_security_group.id] # secure port 5432 with the instances that belong to app_security_group
  }

  # SSH inbound
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.external.user_public_ip.result.ip}/32"] # secure port 22 with the public ip of the host
  }

  # HTTPS outbound
  egress {
    from_port   = 0
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}