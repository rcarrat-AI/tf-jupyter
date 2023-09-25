variable "availability_zones" {
  type    = list(any)
  default = ["eu-west-1a"]
}

variable "aws_region" {
  default = "eu-west-1"
}

variable "instance_type" {
  default = "g5.xlarge"
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
  default = "1  "
}

variable "ebs_disk_size" {
  type    = string
  default = "100"
}

variable "block_duration_minutes" {
  type    = string
  default = "240"
}

variable "ami_tf" {
  type    = string
  default = "ami-0ddafa3752da513f6"
}
