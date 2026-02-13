resource "confluent_environment" "non_prod" {
  display_name = "non-prod"

  stream_governance {
    package = "ESSENTIALS"
  }
}
