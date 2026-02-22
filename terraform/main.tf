terraform {
    cloud {
      organization = "signalroom"

        workspaces {
            name = "iac-cc-aws-privatelink-infrastructure-networking-example"
        }
    }

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "6.33.0"
        }
        confluent = {
            source  = "confluentinc/confluent"
            version = "2.62.0"
        }
        tfe = {
            source = "hashicorp/tfe"
            version = "~> 0.73.0"
        }
    }
}

resource "confluent_environment" "non_prod" {
  display_name = "non-prod"

  stream_governance {
    package = "ESSENTIALS"
  }
}

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

  depends_on = [ 
    confluent_environment.non_prod 
  ]
}

resource "time_sleep" "wait_for_gateway" {
  depends_on = [ 
    confluent_gateway.non_prod 
  ]

  create_duration = "2m"
}

# ===================================================================================
# SANDBOX VPC KAFKA CLUSTER PRIVATELINK CONFIGURATION
# ===================================================================================
module "sandbox_vpc" {
  source = "./modules/aws-vpc"

  vpc_name          = local.sandbox_vpc_name
  vpc_cidr          = "10.0.0.0/20"
  subnet_count      = 3
  new_bits          = 4
  
  # Transit Gateway configuration
  tgw_id                   = var.tgw_id
  tgw_rt_id                = var.tgw_rt_id

  # PrivateLink configuration from Confluent
  privatelink_service_name = confluent_gateway.non_prod.aws_ingress_private_link_gateway[0].vpc_endpoint_service_name

  # VPN configuration
  vpn_vpc_id               = var.vpn_vpc_id
  vpn_vpc_rt_ids           = local.vpn_vpc_rt_ids
  vpn_client_vpc_cidr      = data.aws_ec2_client_vpn_endpoint.client_vpn.client_cidr_block
  vpn_vpc_cidr             = data.aws_vpc.vpn.cidr_block
  vpn_endpoint_id          = var.vpn_endpoint_id
  vpn_target_subnet_ids    = local.vpn_target_subnet_ids

  # Confluent Cloud configuration
  confluent_environment_id = confluent_environment.non_prod.id

  # Terraform Cloud Agent configuration
  tfc_agent_vpc_id         = var.tfc_agent_vpc_id 
  tfc_agent_vpc_rt_ids     = local.tfc_agent_vpc_rt_ids
  tfc_agent_vpc_cidr       = data.aws_vpc.tfc_agent.cidr_block

  # DNS configuration
  dns_vpc_id               = var.dns_vpc_id
  dns_vpc_rt_ids           = local.dns_vpc_rt_ids
  dns_vpc_cidr             = data.aws_vpc.dns.cidr_block

  depends_on = [ 
    time_sleep.wait_for_gateway
  ]
}

module "sandbox_access_point" {
  source = "./modules/access-point"

  vpc_name                 = local.sandbox_vpc_name
  confluent_environment_id = confluent_environment.non_prod.id
  confluent_gateway_id     = confluent_gateway.non_prod.id
  vpc_endpoint_id          = module.sandbox_vpc.vpc_endpoint_id

  depends_on = [ 
    module.sandbox_vpc
  ]
}

resource "confluent_kafka_cluster" "sandbox_cluster" {
  display_name = "sandbox_cluster"
  availability = "HIGH"
  cloud        = local.cloud
  region       = var.aws_region
  enterprise   {}
  
  environment {
    id = confluent_environment.non_prod.id
  }

  

  depends_on = [ 
    module.sandbox_access_point 
  ]
}

module "sandbox_dns" {
  source                  = "./modules/aws-dns"

  confluent_environment_id = confluent_environment.non_prod.id

  vpc_name                 = local.sandbox_vpc_name
  access_point_dns_domain  = module.sandbox_access_point.access_point_dns_domain
  vpc_endpoint_dns_name    = module.sandbox_vpc.vpc_endpoint_dns_name
  vpc_id                   = module.sandbox_vpc.vpc_id

  dns_vpc_id               = var.dns_vpc_id
  tfc_agent_vpc_id         = var.tfc_agent_vpc_id 
  vpn_vpc_id               = var.vpn_vpc_id

  depends_on = [ 
    confluent_kafka_cluster.sandbox_cluster 
  ]
}

# ===================================================================================
# SHARED VPC KAFKA CLUSTER PRIVATELINK CONFIGURATION
# ===================================================================================
module "shared_vpc" {
  source = "./modules/aws-vpc"

  vpc_name          = local.shared_vpc_name
  vpc_cidr          = "10.1.0.0/20"
  subnet_count      = 3
  new_bits          = 4
  
  # Transit Gateway configuration
  tgw_id                   = var.tgw_id
  tgw_rt_id                = var.tgw_rt_id

  # PrivateLink configuration from Confluent
  privatelink_service_name = confluent_gateway.non_prod.aws_ingress_private_link_gateway[0].vpc_endpoint_service_name

  # VPN configuration
  vpn_vpc_id               = var.vpn_vpc_id
  vpn_vpc_rt_ids           = local.vpn_vpc_rt_ids
  vpn_client_vpc_cidr      = data.aws_ec2_client_vpn_endpoint.client_vpn.client_cidr_block
  vpn_vpc_cidr             = data.aws_vpc.vpn.cidr_block
  vpn_endpoint_id          = var.vpn_endpoint_id
  vpn_target_subnet_ids    = local.vpn_target_subnet_ids

  # Confluent Cloud configuration
  confluent_environment_id = confluent_environment.non_prod.id

  # Terraform Cloud Agent configuration
  tfc_agent_vpc_id         = var.tfc_agent_vpc_id 
  tfc_agent_vpc_rt_ids     = local.tfc_agent_vpc_rt_ids
  tfc_agent_vpc_cidr       = data.aws_vpc.tfc_agent.cidr_block

  # DNS configuration
  dns_vpc_id               = var.dns_vpc_id
  dns_vpc_rt_ids           = local.dns_vpc_rt_ids
  dns_vpc_cidr             = data.aws_vpc.dns.cidr_block

  depends_on = [ 
    module.sandbox_dns
  ]
}

module "shared_access_point" {
  source = "./modules/access-point"

  vpc_name                 = local.shared_vpc_name
  confluent_environment_id = confluent_environment.non_prod.id
  confluent_gateway_id     = confluent_gateway.non_prod.id
  vpc_endpoint_id          = module.shared_vpc.vpc_endpoint_id

  depends_on = [ 
    module.shared_vpc
  ]
}

resource "confluent_kafka_cluster" "shared_cluster" {
  display_name = "shared_cluster"
  availability = "HIGH"
  cloud        = local.cloud
  region       = var.aws_region
  enterprise   {}
  
  environment {
    id = confluent_environment.non_prod.id
  }

  depends_on = [ 
    module.shared_access_point 
  ]
}

module "shared_dns" {
  source                  = "./modules/aws-dns"

  confluent_environment_id = confluent_environment.non_prod.id

  vpc_name                 = local.shared_vpc_name
  access_point_dns_domain  = module.shared_access_point.access_point_dns_domain
  vpc_endpoint_dns_name    = module.shared_vpc.vpc_endpoint_dns_name
  vpc_id                   = module.shared_vpc.vpc_id

  dns_vpc_id               = var.dns_vpc_id
  tfc_agent_vpc_id         = var.tfc_agent_vpc_id 
  vpn_vpc_id               = var.vpn_vpc_id


  depends_on = [ 
    confluent_kafka_cluster.shared_cluster 
  ]
}
