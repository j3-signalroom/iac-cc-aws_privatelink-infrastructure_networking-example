data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  available_zones = slice(data.aws_availability_zones.available.names, 0, var.subnet_count)
}
