## TODO: Adjust the deep learning AMIs
data "aws_ami" "al2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Deep Learning AMI GPU TensorFlow *"]
  }

  owners = ["amazon"]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.0"

  name = var.name
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

}

resource "aws_key_pair" "key" {
  key_name   = "${var.name}-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "jupyter" {
  name        = "${var.name}-sg"
  description = "${var.name}-sg"
  vpc_id      = module.vpc.vpc_id


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  ingress {
    from_port   = 8888
    to_port     = 8898
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-sg"
  }

}
