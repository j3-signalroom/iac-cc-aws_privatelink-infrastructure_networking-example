variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "subnet_count" {
  description = "Number of subnets to create"
  type        = number
}

variable "new_bits" {
    description = "New bit"
    type = number
}

variable "privatelink_service_name" {
  description = "AWS VPC Endpoint Service Name from Confluent Private Link Attachment"
  type        = string
}

variable "dns_domain" {
  description = "DNS domain from Confluent Private Link Attachment (e.g., us-east-1.aws.private.confluent.cloud)"
  type        = string
}

variable "confluent_environment_id" {
  description = "Confluent Environment ID"
  type        = string
}

variable "confluent_platt_id" {
  description = "Confluent PrivateLink Attachment ID"
  type        = string
}

variable "tgw_id" {
  description = "Transit Gateway ID to attach the PrivateLink VPC to"
  type        = string
} 

variable "tgw_rt_id" {
  description = "Transit Gateway Route Table ID to associate the PrivateLink VPC attachment with"
  type        = string
}

variable "vpn_client_vpc_cidr" {
  description = "VPN Client VPC CIDR"
  type        = string
}

variable "tfc_agent_vpc_id" {
  description = "Terraform Cloud Agent VPC ID (for tagging PHZ association purposes)"
  type        = string
}

variable "tfc_agent_vpc_cidr" {
  description = "Terraform Cloud Agent VPC CIDR"
  type        = string
}

variable "shared_phz_id" {
  description = "Optional: Existing Route53 Private Hosted Zone ID. If provided, the module will use this instead of creating a new one. Leave empty to create a new PHZ."
  type        = string
  default     = null
}

variable "dns_vpc_cidr" {
  description = "DNS VPC CIDR"
  type        = string
}

variable "vpn_vpc_cidr" {
  description = "VPN VPC CIDR"
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