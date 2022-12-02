edge "vpc_subnet_to_vpc_vpc" {
  title = "vpc"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      vpc_id as to_id
    from
      aws_vpc_subnet
    where
      subnet_id = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}
