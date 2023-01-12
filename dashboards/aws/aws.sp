locals {
  aws_common_tags = {
    service = "AWS"
  }
}

category "account" {
  title = "Account"
  color = local.compute_color
  icon  = "cloud_circle"
}

category "availability_zone" {
  title = "Availability Zone"
  color = local.networking_color
  icon  = "apartment"
}

category "region" {
  title = "Region"
  color = local.compute_color
  icon  = "travel_explore"
}
