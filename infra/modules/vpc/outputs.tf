output "capstone_vpc_id" {
  description = "Id of Capstone VPC"
  value = aws_vpc.capstone_vpc_main.id
}

output "capstone_security_group_id" {
  description = "Id of Capstone security group"
  value = aws_security_group.capstone_allow_http.id
}

output "capstone_subnet_main" {
  description = "Id of Capstone subnet"
  value = aws_subnet.capstone_sb_main.id
}

output "capstone_subnet_secondary" {
  description = "Id of Capstone secondary subnet"
  value = aws_subnet.capstone_sb_secondary.id
}