output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Map of public subnet IDs"
  value       = { for az, subnet in aws_subnet.public_sub : az => subnet.id }
}