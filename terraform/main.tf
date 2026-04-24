terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

data "aws_vpc" "default" {
  default = true
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

resource "aws_security_group" "lab6_sg" {
  name        = "lab6-terraform-sg"
  description = "Allow SSH and HTTP traffic for Lab 6"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Lab6-Terraform-Security-Group"
  }
}

resource "aws_instance" "lab6_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = "kna"
  vpc_security_group_ids = [aws_security_group.lab6_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io
    systemctl enable docker
    systemctl start docker

    docker pull ch1fir/iit-lab5:latest

    docker run -d \
      --name lab4-container \
      --restart unless-stopped \
      -p 80:80 \
      ch1fir/iit-lab5:latest

     docker run -d \
	  --name watchtower \
	  --restart unless-stopped \
 	 -e DOCKER_API_VERSION=1.44 \
  	-v /var/run/docker.sock:/var/run/docker.sock \
 	 containrrr/watchtower \
 	 --interval 30
  EOF

  tags = {
    Name = "Lab6-Terraform-Instance"
  }
}

output "instance_public_ip" {
  description = "Public IP address of the created EC2 instance"
  value       = aws_instance.lab6_instance.public_ip
}

output "website_url" {
  description = "URL of the deployed web application"
  value       = "http://${aws_instance.lab6_instance.public_ip}"
}