variable "availability_zones" {
  type    = list(any)
  default = ["us-east-2a"]
}

variable "aws_region" {
  default = "us-east-2"
}

variable "instance_type" {
  default = "g5.2xlarge"
}

variable "name" {
  default = "jp-tf"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(any)
  default = ["10.0.0.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(any)
  default = ["10.0.10.0/24"]
}

variable "spot_price" {
  type    = string
  default = "0.3636"
}

variable "ebs_disk_size" {
  type    = string
  default = "100"
}


