variable "confluent_environment_id" {
  description = "Confluent Environment ID"
  type        = string
}

variable "confluent_gateway_id" {
  description = "Confluent Gateway ID to associate the PrivateLink VPC attachment with"
  type        = string
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "vpc_endpoint_id" {
  description = "VPC Endpoint ID for the PrivateLink endpoint to associate with the Access Point"
  type        = string
}