# Create the security group
resource "aws_security_group" "privatelink" {
  name        = "ccloud-privatelink_${local.network_id}_${aws_vpc.privatelink.id}"
  description = "Confluent Cloud Private Link Security Group for ${var.dns_domain}"
  vpc_id      = aws_vpc.privatelink.id

  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name        = "ccloud-privatelink-${local.network_id}"
    VPC         = aws_vpc.privatelink.id
    Environment = data.confluent_environment.privatelink.display_name
  }
}

# Create the required SG rule for Kafka REST API access
resource "aws_security_group_rule" "allow_https" {
  description       = "HTTPS from VPC, TFC Agent VPCs, and VPN clients"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.tfc_agent_vpc_cidr, var.vpn_vpc_cidr, var.vpn_client_vpc_cidr, var.vpc_cidr]
  security_group_id = aws_security_group.privatelink.id
}

# Create the required SG rule for Kafka broker access
resource "aws_security_group_rule" "allow_kafka" {
  description       = "Kafka from VPC, TFC Agent VPCs, and VPN clients"
  type              = "ingress"
  from_port         = 9092
  to_port           = 9092
  protocol          = "tcp"
  cidr_blocks       = [var.tfc_agent_vpc_cidr, var.vpn_vpc_cidr, var.vpn_client_vpc_cidr, var.vpc_cidr]
  security_group_id = aws_security_group.privatelink.id
}

# Create the required SG rule for DNS resolution of the PrivateLink endpoint
# UDP (primary) — Used for standard DNS queries. Most DNS lookups are small enough to fit 
# in a single UDP packet (512 bytes, or 4096 with EDNS). It's connectionless, so it's faster 
# with less overhead.
resource "aws_security_group_rule" "allow_dns_udp" {
  description       = "DNS (UDP) from VPC, TFC Agent VPCs, and VPN clients"
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = [var.tfc_agent_vpc_cidr, var.vpn_vpc_cidr, var.vpn_client_vpc_cidr, var.vpc_cidr]
  security_group_id = aws_security_group.privatelink.id
}

# Create the required SG rule for DNS resolution of the PrivateLink endpoint
# TCP (fallback) — Used when a DNS response exceeds the UDP size limit (e.g., large record sets,
# DNSSEC responses), or when zone transfers occur. TCP handles the reliable delivery of larger \
# payloads via its connection-oriented stream.
resource "aws_security_group_rule" "allow_dns_tcp" {
  description       = "DNS (TCP) from VPC, TFC Agent VPCs, and VPN clients"
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = [var.tfc_agent_vpc_cidr, var.vpn_vpc_cidr, var.vpn_client_vpc_cidr, var.vpc_cidr]
  security_group_id = aws_security_group.privatelink.id
}
