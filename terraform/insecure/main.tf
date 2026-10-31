
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Find the latest Ubuntu 22.04 AMI.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# INSECURE: SSH is exposed to the entire internet.
resource "aws_security_group" "insecure_sg" {
  name        = "policy-pipeline-insecure-sg"
  description = "Intentionally insecure security group"

  ingress {
    description = "SSH open to everyone"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# INSECURE: Public IP and unencrypted EBS storage.
resource "aws_instance" "insecure_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.insecure_sg.id
  ]

  root_block_device {
    encrypted = false
  }

  # INSECURE: IMDSv2 is not required.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  tags = {
    Name        = "insecure-policy-lab"
    Environment = "security-testing"
  }
}
