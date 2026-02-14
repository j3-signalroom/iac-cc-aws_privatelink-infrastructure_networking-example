resource "confluent_kafka_cluster" "sandbox_cluster" {
  display_name = "sandbox_cluster"
  availability = "HIGH"
  cloud        = local.cloud
  region       = var.aws_region
  enterprise   {}
  
  environment {
    id = confluent_environment.non_prod.id
  }
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
}
