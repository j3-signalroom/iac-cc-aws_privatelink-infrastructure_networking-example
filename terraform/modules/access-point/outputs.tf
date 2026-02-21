output "access_point_id" {
  description = "The ID of the Confluent Access Point created for PrivateLink connectivity"
  value       = confluent_access_point.privatelink.id
}

output "access_point_service_name" {
  description = "The service name of the Confluent Access Point created for PrivateLink connectivity"
  value       = confluent_access_point.privatelink.aws_ingress_private_link_endpoint[0].vpc_endpoint_service_name
}

output "access_point_dns_domain" {
  description = "The DNS domain of the Confluent Access Point created for PrivateLink connectivity"
  value       = confluent_access_point.privatelink.aws_ingress_private_link_endpoint[0].dns_domain
}