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

# IAM role for the EC2 instance
resource "aws_iam_role" "secure_ec2_role" {
  name = "policy-pipeline-secure-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name      = "secure-policy-ec2-role"
    ManagedBy = "Terraform"
  }
}

# Instance profile attaches the IAM role to EC2
resource "aws_iam_instance_profile" "secure_ec2_profile" {
  name = "policy-pipeline-secure-ec2-profile"
  role = aws_iam_role.secure_ec2_role.name
}

# Security group with restricted SSH access
resource "aws_security_group" "secure_sg" {
  name        = "policy-pipeline-secure-sg"
  description = "Security group with restricted access"

  ingress {
    description = "SSH from approved source only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    description = "HTTPS outbound traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "secure-policy-security-group"
    ManagedBy = "Terraform"
  }
}

# Hardened EC2 instance
resource "aws_instance" "secure_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  associate_public_ip_address = false
  ebs_optimized               = true

  vpc_security_group_ids = [aws_security_group.secure_sg.id]

  iam_instance_profile = aws_iam_instance_profile.secure_ec2_profile.name

  root_block_device {
    encrypted             = true
    volume_type           = "gp3"
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring = true

  tags = {
    Name        = "secure-policy-lab"
    Environment = "security-testing"
    ManagedBy   = "Terraform"
  }
}