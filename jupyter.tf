
data "aws_ami" "al2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"]
}

resource "aws_vpc" "jupyter_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "jupyter_subnet" {
  vpc_id            = aws_vpc.jupyter_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = var.availability_zone
}

resource "aws_key_pair" "key" {
  key_name   = "key-$var.name"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "jupyter" {
  name        = "$var.name-sg"
  description = "$var.name-sg"
  vpc_id      = aws_vpc.jupyter_vpc.id


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

}

resource "aws_instance" "jupyter" {
  ami                    = data.aws_ami.al2.id
  availability_zone      = var.availability_zone
  instance_type          = var.instance_type
  key_name               = aws_key_pair.key.key_name
  vpc_security_group_ids = ["${aws_security_group.jupyter.id}"]
  subnet_id              = aws_subnet.jupyter_subnet.id
  user_data              = file("script.sh")

}

resource "aws_ebs_volume" "jupyter" {
  availability_zone = var.availability_zone
  size              = 8
  type              = "gp2"

}

resource "aws_volume_attachment" "jupyter" {
  device_name  = "/dev/sdb"
  instance_id  = aws_instance.jupyter.id
  volume_id    = aws_ebs_volume.jupyter.id
  force_detach = true
}

