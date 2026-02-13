data "aws_vpc" "tfc_agent" {
  id = var.tfc_agent_vpc_id
}

data "aws_vpc" "dns" {
  id = var.dns_vpc_id
}

data "aws_vpc" "vpn" {
  id = var.vpn_vpc_id
}

data "aws_ec2_client_vpn_endpoint" "client_vpn" {
  filter {
    name   = "tag:Name"
    values = ["client-vpn"]
  }
}
