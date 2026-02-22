resource "aws_vpc" "privatelink" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = var.vpc_name
    ManagedBy = "Terraform Cloud"
  }
}

resource "aws_vpc_endpoint" "privatelink" {
  vpc_id              = aws_vpc.privatelink.id
  service_name        = var.privatelink_service_name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.privatelink.id]
  private_dns_enabled = false
  
  subnet_ids = aws_subnet.private[*].id
  
  tags = {
    Name      = "ccloud-privatelink-${var.vpc_name}"
    VPC       = aws_vpc.privatelink.id
    ManagedBy = "Terraform Cloud"
  }

  depends_on = [
    aws_security_group.privatelink
  ]
}

resource "aws_subnet" "private" {
  count = var.subnet_count

  vpc_id            = aws_vpc.privatelink.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.new_bits, count.index)
  availability_zone = local.available_zones[count.index]

  tags = {
    Name          = "${var.vpc_name}-private-subnet-${count.index + 1}"
    Type          = "private"
    AvailableZone = local.available_zones[count.index]
    ManagedBy     = "Terraform Cloud"
  }
}

# Handles multiple private subnets by creating a route table for each subnet
resource "aws_route_table" "private" {
  count  = var.subnet_count
  
  vpc_id = aws_vpc.privatelink.id
  
  tags = {
    Name      = "${var.vpc_name}-private-rt-${count.index + 1}"
    ManagedBy = "Terraform Cloud"
  }
}

resource "aws_route_table_association" "private" {
  count = var.subnet_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# ============================================================================
# TRANSIT GATEWAY ATTACHMENT
# ============================================================================
resource "aws_ec2_transit_gateway_vpc_attachment" "privatelink" {
  subnet_ids         = aws_subnet.private[*].id
  transit_gateway_id = var.tgw_id
  vpc_id             = aws_vpc.privatelink.id
  
  # Enable DNS support for cross-VPC resolution
  dns_support = "enable"

  tags = {
    Name        = "${aws_vpc.privatelink.id}-ccloud-privatelink-tgw-attachment"
    ManagedBy   = "Terraform Cloud"
    Purpose     = "Confluent PrivateLink connectivity"
  }
}

# Associate with Transit Gateway Route Table
resource "aws_ec2_transit_gateway_route_table_association" "privatelink" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.privatelink.id
  transit_gateway_route_table_id = var.tgw_rt_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "privatelink" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.privatelink.id
  transit_gateway_route_table_id = var.tgw_rt_id
}

# Add route to TFC Agent VPC via Transit Gateway
resource "aws_route" "privatelink_to_tfc_agent" {
  count = var.subnet_count

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = var.tfc_agent_vpc_cidr
  transit_gateway_id     = var.tgw_id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.privatelink
  ]
}

resource "aws_route" "tfc_agent_to_privatelink" {
  count = length(var.tfc_agent_vpc_rt_ids) > 0 ? length(var.tfc_agent_vpc_rt_ids) : 0
  
  route_table_id         = element(var.tfc_agent_vpc_rt_ids, count.index)
  destination_cidr_block = aws_vpc.privatelink.cidr_block
  transit_gateway_id     = var.tgw_id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.privatelink
  ]
}

# Add route to VPN clients via Transit Gateway
resource "aws_route" "privatelink_to_vpn_client" {
  count = var.subnet_count

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = var.vpn_client_vpc_cidr
  transit_gateway_id     = var.tgw_id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.privatelink
  ]
}

# Add route to VPN via Transit Gateway
resource "aws_route" "privatelink_to_vpn_vpc" {
  count = var.subnet_count

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = var.vpn_vpc_cidr
  transit_gateway_id     = var.tgw_id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.privatelink
  ]
}

resource "aws_route" "vpn_to_privatelink" {
  count = length(var.vpn_vpc_rt_ids) > 0 ? length(var.vpn_vpc_rt_ids) : 0
  
  route_table_id         = element(var.vpn_vpc_rt_ids, count.index)
  destination_cidr_block = aws_vpc.privatelink.cidr_block
  transit_gateway_id     = var.tgw_id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.privatelink
  ]
}


# Add route to DNS VPC via Transit Gateway
resource "aws_route" "privatelink_to_dns" {
  count = var.subnet_count
  
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = var.dns_vpc_cidr
  transit_gateway_id     = var.tgw_id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.privatelink
  ]
}

resource "aws_route" "dns_to_privatelink" {
  count = length(var.dns_vpc_rt_ids) > 0 ? length(var.dns_vpc_rt_ids) : 0

  route_table_id         = element(var.dns_vpc_rt_ids, count.index)
  destination_cidr_block = aws_vpc.privatelink.cidr_block
  transit_gateway_id     = var.tgw_id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.privatelink
  ]
}

# ============================================================================
# CLIENT VPN ROUTES TO PRIVATELINK VPC
# ============================================================================
#
# Add Client VPN routes so VPN clients can reach this PrivateLink VPC
resource "aws_ec2_client_vpn_route" "to_privatelink" {
  count = var.vpn_endpoint_id != null ? length(var.vpn_target_subnet_ids) : 0

  client_vpn_endpoint_id = var.vpn_endpoint_id
  destination_cidr_block = aws_vpc.privatelink.cidr_block
  target_vpc_subnet_id   = var.vpn_target_subnet_ids[count.index]
}

# Authorize VPN clients to access this PrivateLink VPC
resource "aws_ec2_client_vpn_authorization_rule" "to_privatelink" {
  count = var.vpn_endpoint_id != null ? 1 : 0

  client_vpn_endpoint_id = var.vpn_endpoint_id
  target_network_cidr    = aws_vpc.privatelink.cidr_block
  authorize_all_groups   = true
}