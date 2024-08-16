output "kuber_public_subnet_a_id" {
  value = aws_subnet.kuber_public_subnet_01.id
}
output "kuber_public_subnet_b_id" {
  value = aws_subnet.kuber_public_subnet_02.id
}
output "kuber_public_subnet_c_id" {
  value = aws_subnet.kuber_public_subnet_03.id
}
output "kuber_private_subnet_a_id" {
  value = aws_subnet.kuber_private_subnet_01.id
}
output "kuber_private_subnet_b_id" {
  value = aws_subnet.kuber_private_subnet_02.id
}
output "kuber_private_subnet_c_id" {
  value = aws_subnet.kuber_private_subnet_03.id
}
output "public_rt_id" {
  value = aws_route_table.kuber_public_rt.id
}
output "private_rt_id" {
  value = aws_route_table.kuber_private_rt.id
}