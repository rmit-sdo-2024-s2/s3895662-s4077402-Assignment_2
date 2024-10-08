terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# configures Ubuntu machine image
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

# identifies key pair
resource "aws_key_pair" "admin" {
  key_name   = "foo_ec2_key"
  public_key = file(var.public_key_path)
}

# creates AWS instance
resource "aws_instance" "foo-server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  key_name        = aws_key_pair.admin.key_name
  security_groups = [aws_security_group.foo_security_group.name]

  tags = {
    Name = "foo-server"
  }
}

# fetches the host's public ip
data "external" "user_public_ip" {
  program = ["bash", "-c", "echo '{\"ip\": \"'$(curl -s http://checkip.amazonaws.com)'\"}'"]
}

resource "aws_security_group" "foo_security_group" {
  name = "foo_security_group"

  # SSH inbound
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.external.user_public_ip.result.ip}/32"] # secures port 22 with the public ip of the host
  }

  # HTTP inbound
  ingress {
    from_port   = 0
    to_port     = 80
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
