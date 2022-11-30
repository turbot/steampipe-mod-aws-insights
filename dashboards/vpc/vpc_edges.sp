edge "vpc_subnet_to_vpc" {
  title = "vpc"

  sql = <<-EOQ
    select
      subnet_ids as from_id,
      vpc_ids as to_id
    from
      unnest($1::text[]) as subnet_ids,
      unnest($2::text[]) as vpc_ids
  EOQ

  param "subnet_ids" {}
  param "vpc_ids" {}
}
