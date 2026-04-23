output "cluster_vpc_id" { value = aws_vpc.cluster.id }
output "cluster_private_subnets" { value = aws_subnet.private[*].id }
output "cluster_public_subnets" { value = aws_subnet.public[*].id }
output "cluster_db_subnets" { value = aws_subnet.db[*].id }
output "cluster_private_route_tables" { value = aws_route_table.private[*].id }
output "support_vpc_id" { value = aws_vpc.support.id }
output "support_private_subnets" { value = aws_subnet.support_private[*].id }
output "support_private_route_tables" { value = aws_route_table.support_private[*].id }
