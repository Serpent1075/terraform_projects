resource "aws_subnet" "kuber_public_subnet_01" {
  vpc_id     = var.vpc_id
  cidr_block = var.cidr_kuber_pub_a
  availability_zone = var.az_a
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-Kuber-Public-2a"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }
}

resource "aws_subnet" "kuber_public_subnet_02" {
  vpc_id     = var.vpc_id
  cidr_block = var.cidr_kuber_pub_b
  availability_zone = var.az_b
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-Kuber-Public-2b"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }
}

resource "aws_subnet" "kuber_public_subnet_03" {
  vpc_id     = var.vpc_id
  cidr_block = var.cidr_kuber_pub_c
  availability_zone = var.az_c
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-Kuber-Public-2c"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }
}
resource "aws_subnet" "kuber_private_subnet_01" {
  vpc_id     = var.vpc_id
  cidr_block = var.cidr_kuber_pri_a
  availability_zone = var.az_a

  tags = {
    Name = "${var.prefix}-Kuber-Pri-2a"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

resource "aws_subnet" "kuber_private_subnet_02" {
  vpc_id     = var.vpc_id
  cidr_block = var.cidr_kuber_pri_b
  availability_zone = var.az_b

  tags = {
    Name = "${var.prefix}-Kuber-Pri-2b"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}
resource "aws_subnet" "kuber_private_subnet_03" {
  vpc_id     = var.vpc_id
  cidr_block = var.cidr_kuber_pri_c
  availability_zone = var.az_c

  tags = {
    Name = "${var.prefix}-Kuber-Pri-2c"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}


resource "aws_route_table" "kuber_public_rt" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  tags = {
    Name = "${var.prefix}-Kuber-Pub-Routing-Table"
  }
}

resource "aws_route_table_association" "kuber-pub-subnet-01-route-table" {
  subnet_id      = aws_subnet.kuber_public_subnet_01.id
  route_table_id = aws_route_table.kuber_public_rt.id
}

resource "aws_route_table_association" "pub-subnet-02-route-table" {
  subnet_id      = aws_subnet.kuber_public_subnet_02.id
  route_table_id = aws_route_table.kuber_public_rt.id
}

resource "aws_route_table_association" "pub-subnet-03-route-table" {
  subnet_id      = aws_subnet.kuber_public_subnet_03.id
  route_table_id = aws_route_table.kuber_public_rt.id
}

resource "aws_route_table" "kuber_private_rt" {
  vpc_id = var.vpc_id

/*

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.kuber_ngw.id
  }
*/  
  tags = {
    Name = "${var.prefix}-Kuber-Pri-Routing-Table"
  }
}

resource "aws_route_table_association" "pri-subnet-01-route-table" {
  subnet_id      = aws_subnet.kuber_private_subnet_01.id
  route_table_id = aws_route_table.kuber_private_rt.id
}

resource "aws_route_table_association" "pri-subnet-02-route-table" {
  subnet_id      = aws_subnet.kuber_private_subnet_02.id
  route_table_id = aws_route_table.kuber_private_rt.id
}

resource "aws_route_table_association" "pri-subnet-03-route-table" {
  subnet_id      = aws_subnet.kuber_private_subnet_03.id
  route_table_id = aws_route_table.kuber_private_rt.id
}
/*
resource "aws_eip" "eip-kuber-ngw" {
  vpc                       = true
  associate_with_private_ip = var.pub_kuber_nat_eip_private
  
  tags = {
    Name = "${var.prefix}-kuber-nat-eip-ngw"
  }
}

resource "aws_nat_gateway" "kuber_ngw" {
  allocation_id = aws_eip.eip-kuber-ngw.id
  subnet_id     = aws_subnet.kuber_public_subnet_01.id
  connectivity_type = "public"

  tags = {
    Name = "${var.prefix}-Kuber-NatGateway-01"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [var.igw_id]
}

*/