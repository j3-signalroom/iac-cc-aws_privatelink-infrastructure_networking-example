# The gateway is a cloud-native Kafka proxy solution designed to simplify connectivity to and from 
# Confluent Cloud Kafka cluster services.  It provides a secure and efficient way to connect your
# applications and services to Confluent Cloud, enabling seamless integration and communication with
# your Kafka clusters (i.e., abstracting away complex broker lists, inconsistent security settings,
# and the operational overhead of managing direct client-to-cluster connections).
resource "confluent_gateway" "non_prod" {
  display_name = "${confluent_environment.non_prod.display_name}-privatelink-gateway"

  environment {
    id = confluent_environment.non_prod.id
  }

  aws_ingress_private_link_gateway {
      region = var.aws_region
   }
}

# ===================================================================================
# SANDBOX VPC AND PRIVATELINK CONFIGURATION
# ===================================================================================
module "sandbox_vpc_privatelink" {
  source = "./modules/aws-vpc-confluent-privatelink"

  vpc_name          = "sandbox-${confluent_environment.non_prod.display_name}"
  vpc_cidr          = "10.0.0.0/20"
  subnet_count      = 3
  new_bits          = 4
  
  # Transit Gateway configuration
  tgw_id                   = var.tgw_id
  tgw_rt_id                = var.tgw_rt_id

  # PrivateLink configuration from Confluent
  privatelink_service_name = confluent_private_link_attachment.non_prod.aws[0].vpc_endpoint_service_name
  dns_domain               = confluent_private_link_attachment.non_prod.dns_domain
  
  # VPN configuration
  vpn_vpc_id               = var.vpn_vpc_id
  vpn_vpc_rt_ids           = local.vpn_vpc_rt_ids
  vpn_client_vpc_cidr      = data.aws_ec2_client_vpn_endpoint.client_vpn.client_cidr_block
  vpn_vpc_cidr             = data.aws_vpc.vpn.cidr_block
  vpn_endpoint_id          = var.vpn_endpoint_id
  vpn_target_subnet_ids    = local.vpn_target_subnet_ids

  # Confluent Cloud configuration
  confluent_environment_id = confluent_environment.non_prod.id
  confluent_platt_id       = confluent_private_link_attachment.non_prod.id

  # Terraform Cloud Agent configuration
  tfc_agent_vpc_id         = var.tfc_agent_vpc_id 
  tfc_agent_vpc_rt_ids     = local.tfc_agent_vpc_rt_ids
  tfc_agent_vpc_cidr       = data.aws_vpc.tfc_agent.cidr_block

  # DNS configuration
  dns_vpc_id               = var.dns_vpc_id
  dns_vpc_rt_ids           = local.dns_vpc_rt_ids
  dns_vpc_cidr             = data.aws_vpc.dns.cidr_block

  # Use shared PHZ
  shared_phz_id            = aws_route53_zone.centralized_dns_vpc.zone_id

  depends_on = [ 
    confluent_private_link_attachment.non_prod
  ]
}

# ===================================================================================
# SHARED VPC AND PRIVATELINK CONFIGURATION
# ===================================================================================
module "shared_vpc_privatelink" {
  source = "./modules/aws-vpc-confluent-privatelink"

  vpc_name          = "shared-${confluent_environment.non_prod.display_name}"
  vpc_cidr          = "10.1.0.0/20"
  subnet_count      = 3
  new_bits          = 4
  
  # Transit Gateway configuration
  tgw_id                   = var.tgw_id
  tgw_rt_id                = var.tgw_rt_id

  # PrivateLink configuration from Confluent
  privatelink_service_name = confluent_private_link_attachment.non_prod.aws[0].vpc_endpoint_service_name
  dns_domain               = confluent_private_link_attachment.non_prod.dns_domain
  
  # VPN configuration
  vpn_vpc_id               = var.vpn_vpc_id
  vpn_vpc_rt_ids           = local.vpn_vpc_rt_ids
  vpn_client_vpc_cidr      = data.aws_ec2_client_vpn_endpoint.client_vpn.client_cidr_block
  vpn_vpc_cidr             = data.aws_vpc.vpn.cidr_block
  vpn_endpoint_id          = var.vpn_endpoint_id
  vpn_target_subnet_ids    = local.vpn_target_subnet_ids

  # Confluent Cloud configuration
  confluent_environment_id = confluent_environment.non_prod.id
  confluent_platt_id       = confluent_private_link_attachment.non_prod.id

  # Terraform Cloud Agent configuration
  tfc_agent_vpc_id         = var.tfc_agent_vpc_id 
  tfc_agent_vpc_rt_ids     = local.tfc_agent_vpc_rt_ids
  tfc_agent_vpc_cidr       = data.aws_vpc.tfc_agent.cidr_block

  # DNS configuration
  dns_vpc_id               = var.dns_vpc_id
  dns_vpc_rt_ids           = local.dns_vpc_rt_ids
  dns_vpc_cidr             = data.aws_vpc.dns.cidr_block

  # Use shared PHZ
  shared_phz_id            = aws_route53_zone.centralized_dns_vpc.zone_id

  depends_on = [ 
    confluent_private_link_attachment.non_prod
  ]
}

# ===================================================================================
# DNS RECORDS FOR SANDBOX AND SHARED VPC
# ===================================================================================
#
# Zonal records for Sandbox
resource "aws_route53_record" "privatelink_zonal" {
  for_each = module.sandbox_vpc_privatelink.vpc_subnet_details
  
  zone_id = aws_route53_zone.centralized_dns_vpc.zone_id
  name    = "*.${each.value.availability_zone_id}.${confluent_private_link_attachment.non_prod.dns_domain}"
  type    = "CNAME"
  ttl     = 60
  
  records = [
    format("%s-%s%s",
      split(".", module.sandbox_vpc_privatelink.vpc_endpoint_dns)[0],
      each.value.availability_zone,
      replace(
        module.sandbox_vpc_privatelink.vpc_endpoint_dns,
        split(".", module.sandbox_vpc_privatelink.vpc_endpoint_dns)[0],
        ""
      )
    )
  ]
  
  depends_on = [
    module.sandbox_vpc_privatelink
  ]
}

# Wildcard record for Sandbox
resource "aws_route53_record" "privatelink_wildcard" {
  zone_id = aws_route53_zone.centralized_dns_vpc.zone_id
  name    = "*.${confluent_private_link_attachment.non_prod.dns_domain}"
  type    = "CNAME"
  ttl     = 60
  records = [module.sandbox_vpc_privatelink.vpc_endpoint_dns]
  
  depends_on = [
    module.sandbox_vpc_privatelink
  ]
}

# ===================================================================================
# DNS CONFIGURATION - Manage existing PHZ and SYSTEM Resolver Rule
# ===================================================================================
resource "aws_route53_zone" "centralized_dns_vpc" {
  name = confluent_private_link_attachment.non_prod.dns_domain

  vpc {
    vpc_id = var.tfc_agent_vpc_id
  }

  tags = {
    Name      = "Centralized Confluent PrivateLink PHZ"
    Purpose   = "DNS for all Confluent clusters via PrivateLink"
    ManagedBy = "Terraform Cloud"
  }
}

# Associate the TFC Agent VPC PHZ with the Centralized DNS VPC PHZ
resource "aws_route53_zone_association" "confluent_to_dns_vpc" {
  zone_id = aws_route53_zone.centralized_dns_vpc.zone_id
  vpc_id  = var.dns_vpc_id

  depends_on = [ 
    aws_route53_zone.centralized_dns_vpc
  ]
}

resource "aws_route53_zone_association" "confluent_to_vpn_vpc" {
  zone_id = aws_route53_zone.centralized_dns_vpc.zone_id
  vpc_id  = var.vpn_vpc_id

  depends_on = [ 
    aws_route53_zone.centralized_dns_vpc
  ]
}

# ===========================================================================================================
# SYSTEM RESOLVER RULE
# ===========================================================================================================
#
# A SYSTEM resolver rule tells Route 53 Resolver to use the default VPC DNS resolution
# behavior for that domain — meaning it resolves using the Route 53 Private Hosted Zone (PHZ) 
# associated with the VPC, rather than forwarding the query elsewhere.
# 
# Why it's needed:
# By default, VPC DNS resolution already checks PHZs. But if there are any FORWARD resolver
# rules (e.g., sending DNS queries to on-prem or another DNS server) that match a broader
# domain, they take precedence. A SYSTEM rule for a specific domain like our Confluent
# PrivateLink domain overrides that and says:
#
# "For this specific domain, don't forward — resolve it locally using the shared PHZ."
#
# Rule precedence in Route 53 Resolver:
#
# 1. Most specific domain match wins
# 2. If same specificity: FORWARD beats SYSTEM
# 3. A SYSTEM rule on a specific subdomain beats a FORWARD rule on a parent domain
#
# So in our case, this ensures that DNS queries for confluent_private_link_attachment.non_prod.dns_domain
# resolve to the PrivateLink endpoint IPs in your PHZ, even if a broader forwarding rule exists in
# the environment.
#
# Note: If your VPCs have no conflicting FORWARD rules, you might get away without this. But it's a best practice
# to explicitly define it to avoid any surprises in complex environments.
#
#
# Create a SYSTEM resolver rule for the Confluent PrivateLink domain
resource "aws_route53_resolver_rule" "confluent_private_system" {
  domain_name = confluent_private_link_attachment.non_prod.dns_domain
  name        = "confluent-privatelink-phz-system"
  rule_type   = "SYSTEM"

  tags = {
    Name      = "Confluent PrivateLink PHZ System Rule"
    Purpose   = "Enable PHZ resolution for private Confluent clusters"
    ManagedBy = "Terraform Cloud"
  }
}

# ===================================================================================
# SYSTEM RESOLVER RULE VPC ASSOCIATIONS
# ===================================================================================
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

resource "aws_route53_resolver_rule_association" "confluent_private_sandbox_vpc" {
  resolver_rule_id = aws_route53_resolver_rule.confluent_private_system.id
  vpc_id           = module.sandbox_vpc_privatelink.vpc_id
  name             = "sandbox-vpc-confluent-private"
}

resource "aws_route53_resolver_rule_association" "confluent_private_shared_vpc" {
  resolver_rule_id = aws_route53_resolver_rule.confluent_private_system.id
  vpc_id           = module.shared_vpc_privatelink.vpc_id
  name             = "shared-vpc-confluent-private"
}

# ===================================================================================
# WAIT FOR DNS PROPAGATION
# ===================================================================================
resource "time_sleep" "wait_for_dns" {
  depends_on = [
    aws_route53_record.privatelink_zonal,
    aws_route53_record.privatelink_wildcard,
    aws_route53_zone.centralized_dns_vpc,
    aws_route53_resolver_rule.confluent_private_system,
    aws_route53_resolver_rule_association.confluent_private_dns_vpc,
    aws_route53_resolver_rule_association.confluent_private_vpn_vpc,
    aws_route53_resolver_rule_association.confluent_private_tfc_vpc,
    aws_route53_zone_association.confluent_to_dns_vpc,
    aws_route53_zone_association.confluent_to_vpn_vpc
  ]
  
  create_duration = "2m"
}
