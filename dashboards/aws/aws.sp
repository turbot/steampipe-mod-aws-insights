locals {
  aws_common_tags = {
    service = "AWS"
  }
}

category "account" {
  title = "Account"
  icon  = "cloud-circle"
  color = local.compute_color
}

category "availability_zone" {
  title = "Availability Zone"
  icon  = "apartment"
  color = local.networking_color
}

category "region" {
  title = "Region"
  icon  = "travel-explore"
  color = local.compute_color
}
