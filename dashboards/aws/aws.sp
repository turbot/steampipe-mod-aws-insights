locals {
  aws_common_tags = {
    service = "AWS"
  }
}

category "account" {
  title = "Account"
  icon  = "heroicons-outline:globe-alt"
  color = local.compute_color
}

category "availability_zone" {
  title = "Availability Zone"
  icon  = "heroicons-outline:building-office"
  color = local.networking_color
}

category "region" {
  title = "Region"
  icon  = "heroicons-outline:globe-americas"
  color = local.compute_color
}
