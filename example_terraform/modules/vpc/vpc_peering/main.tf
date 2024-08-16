resource "aws_vpc_peering_connection" "peer" {
  peer_owner_id = var.account_id
  peer_vpc_id   = var.peer_vpc_id
  vpc_id        = var.vpc_id
  auto_accept   = true

  tags = {
    Name = "VPC Peering ${var.prefix}"
  }
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true

  tags = {
    Side = "${var.prefix} Accepter"
  }
}

resource "aws_route" "host_route" {
  # ID of VPC 2 main route table.
  route_table_id = var.host_route_table_id

  # CIDR block / IP range for VPC 2.
  destination_cidr_block = var.peer_cidr_block

  # ID of VPC peering connection.
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "peer_route" {
  # ID of VPC 2 main route table.
  route_table_id = var.peer_route_table_id

  # CIDR block / IP range for VPC 2.
  destination_cidr_block = var.host_cidr_block

  # ID of VPC peering connection.
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
