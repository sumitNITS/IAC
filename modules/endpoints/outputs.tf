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
  value       = aws_vpc_endpoint.support_interface["ssm"].id
}

output "ssmmessages_endpoint_id" {
  description = "ID of the SSM Messages VPC endpoint in support VPC"
  value       = aws_vpc_endpoint.support_interface["ssmmessages"].id
}

output "ec2messages_endpoint_id" {
  description = "ID of the EC2 Messages VPC endpoint in support VPC"
  value       = aws_vpc_endpoint.support_interface["ec2messages"].id
}

output "support_endpoint_security_group_id" {
  description = "Security group ID used for support VPC endpoints"
  value       = aws_security_group.support_endpoint_sg.id
}

output "endpoint_sg_id" {
  description = "Compatibility alias for cluster endpoint security group ID"
  value       = aws_security_group.endpoint_sg.id
}

output "interface_endpoint_ids" {
  description = "Map of cluster VPC interface endpoint service names to endpoint IDs"
  value = {
    for k, v in aws_vpc_endpoint.interface :
    k => v.id
  }
}

output "support_s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint in support VPC"
  value       = aws_vpc_endpoint.s3_support.id
}
