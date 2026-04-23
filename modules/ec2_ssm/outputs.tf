output "instance_id" {
  description = "SSM EC2 instance ID for jump host access"
  value       = aws_instance.ssm.id
}

output "instance_arn" {
  description = "ARN of the SSM EC2 instance"
  value       = aws_instance.ssm.arn
}

output "security_group_id" {
  description = "Security group ID of the SSM instance"
  value       = aws_security_group.sg.id
}
