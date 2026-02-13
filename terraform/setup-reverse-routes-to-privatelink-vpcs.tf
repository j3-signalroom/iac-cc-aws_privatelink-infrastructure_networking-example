# ===================================================================================
# REVERSE ROUTES: TFC AGENT, VPN, AND DNS VPCs → PRIVATELINK VPCs
# ===================================================================================
#
# The PrivateLink module creates routes FROM the PrivateLink VPCs TO the TFC Agent,
# VPN, and DNS VPCs. But the reverse direction is missing — the TFC Agent, VPN, and
# DNS VPCs need routes TO the PrivateLink VPCs via the Transit Gateway.
#
# Without these routes, traffic from the TFC Agent (running Terraform applies) and
# VPN clients cannot reach the Confluent private endpoints, causing TLS handshake
# timeouts on API key sync checks, cluster linking, topic creation, etc.
# ===================================================================================

# ---------------------------------------------------------------------------
# Look up the MAIN route table for each VPC (resolves at plan time)
# ---------------------------------------------------------------------------
data "aws_route_table" "tfc_agent_main" {
  vpc_id = var.tfc_agent_vpc_id

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

data "aws_route_table" "vpn_main" {
  vpc_id = var.vpn_vpc_id

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

data "aws_route_table" "dns_main" {
  vpc_id = var.dns_vpc_id

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

# ---------------------------------------------------------------------------
# TFC AGENT VPC → PrivateLink VPCs
# ---------------------------------------------------------------------------
resource "aws_route" "tfc_agent_to_sandbox_privatelink" {
  route_table_id         = data.aws_route_table.tfc_agent_main.id
  destination_cidr_block = module.sandbox_vpc_privatelink.vpc_cidr
  transit_gateway_id     = var.tgw_id

  depends_on = [
    module.sandbox_vpc_privatelink
  ]
}

resource "aws_route" "tfc_agent_to_shared_privatelink" {
  route_table_id         = data.aws_route_table.tfc_agent_main.id
  destination_cidr_block = module.shared_vpc_privatelink.vpc_cidr
  transit_gateway_id     = var.tgw_id

  depends_on = [
    module.shared_vpc_privatelink
  ]
}

# ---------------------------------------------------------------------------
# VPN VPC → PrivateLink VPCs
# ---------------------------------------------------------------------------
resource "aws_route" "vpn_to_sandbox_privatelink" {
  route_table_id         = data.aws_route_table.vpn_main.id
  destination_cidr_block = module.sandbox_vpc_privatelink.vpc_cidr
  transit_gateway_id     = var.tgw_id

  depends_on = [
    module.sandbox_vpc_privatelink
  ]
}

resource "aws_route" "vpn_to_shared_privatelink" {
  route_table_id         = data.aws_route_table.vpn_main.id
  destination_cidr_block = module.shared_vpc_privatelink.vpc_cidr
  transit_gateway_id     = var.tgw_id

  depends_on = [
    module.shared_vpc_privatelink
  ]
}

# ---------------------------------------------------------------------------
# DNS VPC → PrivateLink VPCs
# ---------------------------------------------------------------------------
resource "aws_route" "dns_to_sandbox_privatelink" {
  route_table_id         = data.aws_route_table.dns_main.id
  destination_cidr_block = module.sandbox_vpc_privatelink.vpc_cidr
  transit_gateway_id     = var.tgw_id

  depends_on = [
    module.sandbox_vpc_privatelink
  ]
}

resource "aws_route" "dns_to_shared_privatelink" {
  route_table_id         = data.aws_route_table.dns_main.id
  destination_cidr_block = module.shared_vpc_privatelink.vpc_cidr
  transit_gateway_id     = var.tgw_id

  depends_on = [
    module.shared_vpc_privatelink
  ]
}
