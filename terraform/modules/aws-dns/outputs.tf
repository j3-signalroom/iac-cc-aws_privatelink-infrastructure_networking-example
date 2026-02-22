output "zone_id" {
  description = "Route53 Private Hosted Zone ID"
  value       = aws_route53_zone.privatelink.zone_id
}

output "zone_name" {
  description = "Route53 Private Hosted Zone name (access point DNS domain)"
  value       = aws_route53_zone.privatelink.name
}

output "resolver_rule_id" {
  description = "Route53 Resolver SYSTEM rule ID"
  value       = aws_route53_resolver_rule.confluent_private_system.id
}
