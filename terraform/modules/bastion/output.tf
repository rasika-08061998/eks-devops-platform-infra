output "bastion_instance_id" {
  description = "Bastion EC2 instance ID"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IP of bastion"
  value       = aws_instance.bastion.public_ip
}

output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}