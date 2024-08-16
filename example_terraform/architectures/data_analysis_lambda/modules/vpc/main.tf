resource "aws_vpc" "vpc-seoul-01" {
  cidr_block = var.cidr_vpc
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-vpc-new"
  }
}

resource "aws_subnet" "public-subnet-01" {
  vpc_id     = aws_vpc.vpc-seoul-01.id
  cidr_block = var.cidr_pub_a
  availability_zone = var.az_a

  tags = {
    Name = "${var.prefix}-Pub-2a"
  }
}

resource "aws_subnet" "public-subnet-02" {
  vpc_id     = aws_vpc.vpc-seoul-01.id
  cidr_block = var.cidr_pub_c
  availability_zone = var.az_c

  tags = {
    Name = "${var.prefix}-Pub-2c"
  }
}

resource "aws_subnet" "private-subnet-01" {
  vpc_id     = aws_vpc.vpc-seoul-01.id
  cidr_block = var.cidr_pri_a
  availability_zone = var.az_a

  tags = {
    Name = "${var.prefix}-Pri-2a"
  }
}

resource "aws_subnet" "private-subnet-02" {
  vpc_id     = aws_vpc.vpc-seoul-01.id
  cidr_block = var.cidr_pri_c
  availability_zone = var.az_c

  tags = {
    Name = "${var.prefix}-Pri-2c"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc-seoul-01.id

  tags = {
    Name = "${var.prefix}-igw"
  }
}
/*
resource "aws_eip" "eip-ngw" {
  vpc                       = true
  associate_with_private_ip = var.pub_nat_eip_private
  
  tags = {
    Name = "${var.prefix}-eip-ngw"
  }
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.eip-ngw.id
  subnet_id     = aws_subnet.public-subnet-01.id
  connectivity_type = "public"

  tags = {
    Name = "${var.prefix}-NatGateway-01"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}
*/

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc-seoul-01.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.prefix}-Pub-Routing-Table"
  }
}

resource "aws_route_table_association" "pub-subnet-01-route-table" {
  subnet_id      = aws_subnet.public-subnet-01.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "pub-subnet-02-route-table" {
  subnet_id      = aws_subnet.public-subnet-02.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.vpc-seoul-01.id

/*
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }
*/
  tags = {
    Name = "${var.prefix}-Pri-Routing-Table"
  }
}

resource "aws_route_table_association" "pri-subnet-01-route-table" {
  subnet_id      = aws_subnet.private-subnet-01.id
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_route_table_association" "pri-subnet-02-route-table" {
  subnet_id      = aws_subnet.private-subnet-02.id
  route_table_id = aws_route_table.private-rt.id
}


resource "aws_route_table" "batch-rt" {
  vpc_id = aws_vpc.vpc-seoul-01.id


  tags = {
    Name = "${var.prefix}-Batch-Routing-Table"
  }
}

resource "aws_route_table_association" "batch-subnet-01-route-table" {
  subnet_id      = aws_subnet.batch-subnet-01.id
  route_table_id = aws_route_table.batch-rt.id
}

resource "aws_route_table_association" "batch-subnet-02-route-table" {
  subnet_id      = aws_subnet.batch-subnet-02.id
  route_table_id = aws_route_table.batch-rt.id
}