resource "confluent_access_point" "privatelink" {
  display_name = "ccloud-accesspoint-${var.vpc_name}"

  environment {
    id = var.confluent_environment_id
  }

  gateway {
    id = var.confluent_gateway_id
  }

  aws_ingress_private_link_endpoint {
    vpc_endpoint_id = var.vpc_endpoint_id
  }
}
