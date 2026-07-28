output "public_ip" {
  value = aws_instance.devflow.public_ip
}

output "instance_id" {
  value = aws_instance.devflow.id
}
