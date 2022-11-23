locals {
  aws_common_tags = {
    service = "AWS"
  }
}

category "aws_account" {
  title = "Account"
  icon  = "globe-alt"
  color = local.compute_color
}

category "aws_availability_zone" {
  title = "Availability Zone"
  icon  = "building-office"
  color = local.networking_color
}

category "aws_region" {
  title = "Region"
  icon  = "globe-americas"
  color = local.compute_color
}
