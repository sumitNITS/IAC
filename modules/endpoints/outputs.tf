output "s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "endpoint_security_group_id" {
  description = "Security group ID used for cluster VPC endpoints"
  value       = aws_security_group.endpoint_sg.id
}

output "ssm_endpoint_id" {
  description = "ID of the SSM VPC endpoint in support VPC"
  value       = aws_vpc_endpoint.ssm.id
}

output "ssmmessages_endpoint_id" {
  description = "ID of the SSM Messages VPC endpoint in support VPC"
  value       = aws_vpc_endpoint.ssmmessages.id
}

output "ec2messages_endpoint_id" {
  description = "ID of the EC2 Messages VPC endpoint in support VPC"
  value       = aws_vpc_endpoint.ec2messages.id
}

output "support_endpoint_security_group_id" {
  description = "Security group ID used for support VPC endpoints"
  value       = aws_security_group.support_endpoint_sg.id
}

output "endpoint_ids" {
  description = "VPC endpoint IDs for S3 and ECR (interface endpoints)"
  value       = aws_vpc_endpoint.interface
}

output "endpoint_sg_id" {
  value = aws_security_group.endpoint_sg.id
}

output "interface_endpoint_ids" {
  value = {
    for k, v in aws_vpc_endpoint.interface :
    k => v.id
  }
}

output "interface_endpoints" {
  value = {
    for k, v in aws_vpc_endpoint.interface :
    k => v.id
  }
}