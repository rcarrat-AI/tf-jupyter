## On-Demand Jupyter
# resource "aws_instance" "jupyter" {
#   count = length(var.availability_zones)
#   # ami                         = data.aws_ami.al2.id
#   ami                         = var.ami_tf
#   availability_zone           = var.availability_zones[count.index]
#   instance_type               = var.instance_type
#   key_name                    = aws_key_pair.key.key_name
#   vpc_security_group_ids      = ["${aws_security_group.jupyter.id}"]
#   subnet_id                   = module.vpc.public_subnets[count.index] # Select the appropriate subnet
#   user_data                   = file("script.sh")
#   associate_public_ip_address = true
#   tags = {
#     Name = "${var.name}-${count.index + 1}"
#   }

#   root_block_device {
#     volume_size = 100
#     volume_type = "gp2"
#   }

# }

# resource "aws_ebs_volume" "jupyter" {
#   count             = length(var.availability_zones)
#   availability_zone = var.availability_zones[count.index]
#   size              = var.ebs_disk_size
#   type              = "gp2"

# }

# resource "aws_volume_attachment" "jupyter" {
#   count        = length(var.availability_zones)
#   device_name  = "/dev/sdb"
#   instance_id  = module.ec2_instance[count.index].id
#   volume_id    = aws_ebs_volume.jupyter[count.index].id
#   force_detach = true
# }

