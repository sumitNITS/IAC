output "peering_connection_id" {
  description = "ID of the VPC peering connection"
  value       = aws_vpc_peering_connection.peer.id
}

output "peering_connection_status" {
  description = "Status of the VPC peering connection"
  value       = aws_vpc_peering_connection.peer.accept_status
}
