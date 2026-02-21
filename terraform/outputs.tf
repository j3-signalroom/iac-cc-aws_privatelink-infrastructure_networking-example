output "all_sandbox_cluster_attributes" {
  description = "All attributes of the sandbox cluster"
  value       = module.sandbox_vpc
}

output "all_shared_cluster_attributes" {
  description = "All attributes of the shared cluster"
  value       = module.shared_vpc
}

output "tfc_agent_vpc_cidr_block" {
  description = "VPC TFC Cloud CIDR Block"
  value       = data.aws_vpc.tfc_agent.cidr_block
}

output "dns_vpc_cidr_block" {
  description = "VPC DNS CIDR Block"
  value       = data.aws_vpc.dns.cidr_block
}

output "vpn_vpc_cidr_block" {
  description = "VPN VPC CIDR Block"
  value       = data.aws_vpc.vpn.cidr_block
}

output "vpn_vpc_client_cidr_block" {
  description = "VPN VPC Client CIDR Block"
  value       = data.aws_ec2_client_vpn_endpoint.client_vpn.client_cidr_block
}

output "confluent_environment_id" {
  description = "Confluent Cloud Environment ID"
  value       = confluent_environment.non_prod.id
} 

output "confluent_sandbox_kafka_cluster_id" {
  description = "Confluent Cloud Sandbox Kafka Cluster ID"
  value       = confluent_kafka_cluster.sandbox_cluster.id
}

output "confluent_shared_kafka_cluster_id" {
  description = "Confluent Cloud Shared Kafka Cluster ID"
  value       = confluent_kafka_cluster.shared_cluster.id
}