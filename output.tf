output "ec2_spot_instance_id" {
  description = "The ID of the instance"
  value       = module.ec2_instance[*].id
}

output "ec2_spot_instance_public_ip" {
  description = "The public IP address assigned to the instance, if applicable. NOTE: If you are using an aws_eip with your instance, you should refer to the EIP's address directly and not use `public_ip` as this field will change after the EIP is attached"
  value       = module.ec2_instance[*].public_ip
}

output "spot_instance_id" {
  description = "The Instance ID (if any) that is currently fulfilling the Spot Instance request"
  value       = module.ec2_instance[*].spot_instance_id
}



## On-Demand
# output "jupyter_ip" {

#   value = aws_instance.jupyter[*].public_ip
# }
