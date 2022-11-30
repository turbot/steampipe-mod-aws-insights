locals {
  aws_common_tags = {
    service = "AWS"
  }
}

category "account" {
  title = "Account"
  icon  = "globe-alt"
  color = local.compute_color
}

category "availability_zone" {
  title = "Availability Zone"
  icon  = "building-office"
  color = local.networking_color
}

category "region" {
  title = "Region"
  icon  = "globe-americas"
  color = local.compute_color
}
