terraform {
  backend "s3" {
    bucket  = "bogdanov-i2302-lab6-tfstate"
    key     = "lab6/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "web" {
  ami           = "ami-0b418580298265d5c"
  instance_type = "t3.micro"

  tags = {
    Name = "WebServer-${var.env}"
  }
}

resource "aws_s3_bucket" "storage" {
  bucket = "bogdanov-i2302-lab6-${var.env}"
  acl    = "private"

  tags = {
    Name        = "lab6-bucket-${var.env}"
    Environment = var.env
  }
}
