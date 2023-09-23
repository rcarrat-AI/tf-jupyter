
data "aws_ami" "al2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
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
  key_name   = "key-$var.name"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "jupyter" {
  name        = "$var.name-sg"
  description = "$var.name-sg"
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-jp"
  }

}

resource "aws_instance" "jupyter" {
  count                       = length(var.availability_zones)
  ami                         = data.aws_ami.al2.id
  availability_zone           = var.availability_zones[count.index]
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.key.key_name
  vpc_security_group_ids      = ["${aws_security_group.jupyter.id}"]
  subnet_id                   = module.vpc.public_subnets[count.index] # Select the appropriate subnet
  user_data                   = file("script.sh")
  associate_public_ip_address = true
  tags = {
    Name = "${var.name}-${count.index + 1}"
  }

  root_block_device {
    volume_size = 100
    volume_type = "gp2"
  }

  # instance_market_options {
  #   spot_options {
  #     max_price = var.spot_price
  #   }
}

resource "aws_ebs_volume" "jupyter" {
  count             = length(var.availability_zones)
  availability_zone = var.availability_zones[count.index]
  size              = var.ebs_disk_size
  type              = "gp2"

}

resource "aws_volume_attachment" "jupyter" {
  count        = length(var.availability_zones)
  device_name  = "/dev/sdb"
  instance_id  = aws_instance.jupyter[count.index].id
  volume_id    = aws_ebs_volume.jupyter[count.index].id
  force_detach = true
}

