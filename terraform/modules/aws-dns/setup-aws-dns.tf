# PHZ for this access point's domain — name provided by root after access point is created
resource "aws_route53_zone" "privatelink" {
  name = var.access_point_dns_domain

  vpc {
    vpc_id = var.vpc_id
  }

  # Prevent Terraform from destroying associations managed by aws_route53_zone_association
  lifecycle {
    ignore_changes = [vpc]
  }

  tags = {
    ManagedBy = "Terraform Cloud"
  }
}

resource "aws_route53_record" "privatelink_wildcard" {
  zone_id = aws_route53_zone.privatelink.zone_id
  name    = "*"
  type    = "CNAME"
  ttl     = 60
  records = [var.vpc_endpoint_dns_name]
}

# Associate PHZ with other VPCs
resource "aws_route53_zone_association" "confluent_to_dns_vpc" {
  zone_id = aws_route53_zone.privatelink.zone_id
  vpc_id  = var.dns_vpc_id
}

resource "aws_route53_zone_association" "confluent_to_vpn_vpc" {
  zone_id = aws_route53_zone.privatelink.zone_id
  vpc_id  = var.vpn_vpc_id
}

resource "aws_route53_zone_association" "confluent_to_tfc_vpc" {
  zone_id = aws_route53_zone.privatelink.zone_id
  vpc_id  = var.tfc_agent_vpc_id
}

# SYSTEM resolver rule — domain provided by root after access point is created
resource "aws_route53_resolver_rule" "confluent_private_system" {
  domain_name = var.access_point_dns_domain
  name        = "confluent-privatelink-phz-system-${var.vpc_name}"
  rule_type   = "SYSTEM"

  tags = {
    Name      = "Confluent PrivateLink PHZ System Rule"
    Purpose   = "Enable PHZ resolution for private Confluent clusters"
    ManagedBy = "Terraform Cloud"
  }
}

resource "aws_route53_resolver_rule_association" "confluent_private_dns_vpc" {
  resolver_rule_id = aws_route53_resolver_rule.confluent_private_system.id
  vpc_id           = var.dns_vpc_id
  name             = "dns-vpc-confluent-private"
}

resource "aws_route53_resolver_rule_association" "confluent_private_vpn_vpc" {
  resolver_rule_id = aws_route53_resolver_rule.confluent_private_system.id
  vpc_id           = var.vpn_vpc_id
  name             = "vpn-vpc-confluent-private"
}

resource "aws_route53_resolver_rule_association" "confluent_private_tfc_vpc" {
  resolver_rule_id = aws_route53_resolver_rule.confluent_private_system.id
  vpc_id           = var.tfc_agent_vpc_id
  name             = "tfc-vpc-confluent-private"
}

resource "aws_route53_resolver_rule_association" "confluent_private_local_vpc" {
  resolver_rule_id = aws_route53_resolver_rule.confluent_private_system.id
  vpc_id           = var.vpc_id
  name             = "${var.vpc_name}-vpc-confluent-private"
}
