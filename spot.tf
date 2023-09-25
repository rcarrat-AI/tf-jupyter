# Ec2 Instance using Spot Instances
module "ec2_instance" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  count                       = length(var.availability_zones)
  name                        = "jupyter"
  availability_zone           = var.availability_zones[count.index]
  ami                         = var.ami_tf
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.key.key_name
  vpc_security_group_ids      = ["${aws_security_group.jupyter.id}"]
  subnet_id                   = module.vpc.public_subnets[count.index]
  user_data                   = file("script.sh")
  associate_public_ip_address = true

  create_spot_instance = true
  # spot_price           = var.spot_price
  spot_type = "persistent"

  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 100
    },
  ]

  ebs_block_device = [
    {
      # delete_on_termination = false
      device_name = "/dev/sdb"
      volume_type = "gp3"
      volume_size = 100
    }
  ]

  tags = local.tags

}

resource "aws_ec2_tag" "jupyter" {
  resource_id = module.ec2_instance.0.spot_instance_id
  key         = "Name"
  value       = "JaaS"
}
