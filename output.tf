output "jupyter_ip" {

  value = aws_instance.jupyter[*].public_ip
}
