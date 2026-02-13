terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.40.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.2.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.13.0"
    }
  }
}
