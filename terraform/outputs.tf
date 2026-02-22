output "all_sandbox_vpc_attributes" {
  description = "All attributes of the sandbox VPC"
  value       = module.sandbox_vpc
}

output "all_sandbox_access_point_attributes" {
  description = "All attributes of the sandbox Access Point"
  value       = module.sandbox_access_point
}

output "all_sandbox_dns_attributes" {
  description = "All attributes of the sandbox DNS"
  value       = module.sandbox_dns
}

output "all_shared_vpc_attributes" {
  description = "All attributes of the shared VPC"
  value       = module.shared_vpc
}

output "all_shared_access_point_attributes" {
  description = "All attributes of the shared Access Point"
  value       = module.shared_access_point
}

output "all_shared_dns_attributes" {
  description = "All attributes of the shared DNS"
  value       = module.shared_dns
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

output "sandbox_kafka_cluster_endpoints" {
  description = "Sandbox Kafka Cluster Endpoints"
  value       = confluent_kafka_cluster.sandbox_cluster.endpoints
}

output "shared_kafka_cluster_endpoints" {
  description = "Shared Kafka Cluster Endpoints"
  value       = confluent_kafka_cluster.shared_cluster.endpoints
}

output "deploy_script_arguments" {
  description = "Deploy script arguments for Confluent Cloud resources"
  value = <<-EOT
    =======================================================================================
    Helpful arguments for deploy.sh scripts
    =======================================================================================
      --confluent-environment-id=${confluent_environment.non_prod.id} \
      --confluent-sandbox-kafka-cluster-id=${confluent_kafka_cluster.sandbox_cluster.id} \
      --confluent-shared-kafka-cluster-id=${confluent_kafka_cluster.shared_cluster.id} \
      --confluent-sandbox-access-code-id=${confluent_access_code.sandbox_access_code.id} \
      --confluent-shared-access-code-id=${confluent_access_code.shared_access_code.id}
    =======================================================================================
  EOT
}