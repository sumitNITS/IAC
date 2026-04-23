resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = var.support_vpc_id
  peer_vpc_id = var.cluster_vpc_id
  auto_accept = true
}

resource "aws_route" "support_to_cluster" {
  count                     = length(var.support_route_table_ids)
  route_table_id            = var.support_route_table_ids[count.index]
  destination_cidr_block    = var.cluster_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "cluster_to_support" {
  count                     = length(var.cluster_route_table_ids)
  route_table_id            = var.cluster_route_table_ids[count.index]
  destination_cidr_block    = var.support_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
