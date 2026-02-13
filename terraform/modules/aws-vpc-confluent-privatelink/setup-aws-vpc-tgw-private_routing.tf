# ============================================================================
# VPC, SUBNETS, AND ROUTE TABLES FOR PRIVATELINK
# ============================================================================
resource "aws_vpc" "privatelink" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.vpc_name
  }
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
  }
}

# Handles multiple private subnets by creating a route table for each subnet
resource "aws_route_table" "private" {
  count  = var.subnet_count
  vpc_id = aws_vpc.privatelink.id
  
  tags = {
    Name = "${var.vpc_name}-private-rt-${count.index + 1}"
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
    Environment = data.confluent_environment.privatelink.display_name
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

# =================================================================================
# ROUTE TABLE UPDATES FOR TRANSIT GATEWAY CONNECTIVITY FOR TFC AGENT, VPN, AND DNS
# =================================================================================
#
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
