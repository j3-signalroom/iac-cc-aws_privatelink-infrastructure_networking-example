variable "vpc_id" {
  description = "VPC ID (for tagging PHZ association purposes)"
  type        = string
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "confluent_environment_id" {
  description = "Confluent Environment ID"
  type        = string
}

variable "access_point_dns_domain" {
  description = "DNS domain from the Confluent Access Point — used for the PHZ name and SYSTEM resolver rule"
  type        = string
}

variable "vpc_endpoint_dns_name" {
  description = "DNS name from the VPC Endpoint — used for the PHZ record"
  type        = string
}

variable "tfc_agent_vpc_id" {
  description = "Terraform Cloud Agent VPC ID (for tagging PHZ association purposes)"
  type        = string
}

variable "dns_vpc_id" {
  description = "DNS VPC ID (for tagging PHZ association purposes)"
  type        = string
}

variable "vpn_vpc_id" {
  description = "VPN VPC ID (for tagging PHZ association purposes)"
  type        = string
}
