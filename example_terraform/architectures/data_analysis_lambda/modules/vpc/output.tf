output "vpc_id" {
  value = aws_vpc.vpc-seoul-01.id
}

output "public_subnet_a_id" {
  value = aws_subnet.public-subnet-01.id
}

output "public_subnet_b_id" {
  value = aws_subnet.public-subnet-02.id
}

output "private_subnet_a_id" {
  value = aws_subnet.private-subnet-01.id
}

output "private_subnet_b_id" {
  value = aws_subnet.private-subnet-02.id
}

output "batch_subnet_a_id" {
  value = aws_subnet.batch-subnet-01.id
}

output "batch_subnet_b_id" {
  value = aws_subnet.batch-subnet-02.id
}

output "private_rt_id" {
  value = aws_route_table.private-rt.id
}

output "batch_rt_id" {
  value = aws_route_table.batch-rt.id
}

output "igw_id" {
  value = aws_internet_gateway.igw.id
}

/*
output "ngw_id" {
  value = aws_nat_gateway.ngw.id
}*/