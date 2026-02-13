output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.privatelink.cidr_block
}

output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = aws_vpc.privatelink.default_security_group_id
}
output "private_subnet_ids" {
  description = "List of all private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "List of all private subnet CIDRs"
  value       = aws_subnet.private[*].cidr_block
}

output "private_subnet_azs" {
  description = "List of availability zones for private subnets"
  value       = aws_subnet.private[*].availability_zone
}

output "private_subnet_az_ids" {
  description = "List of availability zone IDs for private subnets"
  value       = aws_subnet.private[*].availability_zone_id
}

output "vpc_rt_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.private[*].id
}

output "route_table_association_ids" {
  description = "List of route table association IDs"
  value       = aws_route_table_association.private[*].id
}

output "subnet_map" {
  description = "Map of subnet names to IDs"
  value = {
    for index, subnet in aws_subnet.private : 
    "${var.vpc_name}-private-subnet-${index + 1}" => subnet.id
  }
}

output "vpc_subnet_details" {
  description = "Detailed information about all subnets keyed by index"
  value = {
    for index, subnet in aws_subnet.private :
    tostring(index) => {  # Use static index as key
      id                   = subnet.id
      cidr_block           = subnet.cidr_block
      availability_zone    = subnet.availability_zone
      availability_zone_id = subnet.availability_zone_id
      name                 = "${var.vpc_name}-private-subnet-${index + 1}"
    }
  }
}

output "vpc_endpoint_id" {
  description = "VPC Endpoint ID for the PrivateLink connection"
  value       = aws_vpc_endpoint.privatelink.id
}

output "vpc_endpoint_dns" {
  description = "VPC Endpoint DNS name"
  value       = aws_vpc_endpoint.privatelink.dns_entry[0]["dns_name"]
}

output "route53_zone_id" {
  description = "Route53 Private Hosted Zone ID (either created or existing)"
  value       = data.aws_route53_zone.shared_phz.zone_id
}

output "route53_zone_name" {
  description = "Route53 Private Hosted Zone name"
  value       = var.dns_domain
}

output "vpc_id" {
  description = "VPC ID where the PrivateLink endpoint is deployed"
  value       = aws_vpc.privatelink.id
}

output "security_group_id" {
  description = "Security Group ID for the VPC endpoint"
  value       = aws_security_group.privatelink.id
}

output "tgw_attachment_id" {
  description = "Transit Gateway VPC Attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.privatelink.id
}

output "confluent_connection_id" {
  description = "Confluent Private Link Attachment Connection ID"
  value       = confluent_private_link_attachment_connection.privatelink.id
}

output "dns_ready" {
  description = "Dependency handle to ensure DNS is fully propagated"
  value       = time_sleep.wait_for_zone_associations.id
}
