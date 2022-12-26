locals {
  aws_common_tags = {
    service = "AWS"
  }
}

category "account" {
  title = "Account"
  icon  = "cloud_circle"
  color = local.compute_color
}

category "availability_zone" {
  title = "Availability Zone"
  icon  = "apartment"
  color = local.networking_color
}

category "region" {
  title = "Region"
  icon  = "travel_explore"
  color = local.compute_color
}
