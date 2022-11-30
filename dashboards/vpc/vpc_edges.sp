edge "vpc_subnet_to_vpc_vpc" {
  title = "vpc"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      vpc_id as to_id
    from
      unnest($1::text[]) as subnet_id,
      unnest($2::text[]) as vpc_id
  EOQ

  param "subnet_ids" {}
  param "vpc_ids" {}
}
