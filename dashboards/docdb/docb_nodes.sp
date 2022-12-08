
node "docdb_cluster" {
  category = category.docdb_cluster

  sql = <<-EOQ
    select
      c.arn as id,
      c.title as title,
      jsonb_build_object(
        'ID', c.db_cluster_identifier,
        'Availability Zone', c.availability_zones,
        'Create Time', c.cluster_create_time,
        'Encrypted', c.storage_encrypted,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      aws_docdb_cluster as c,
      jsonb_array_elements(c.vpc_security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'VpcSecurityGroupId'
    where
      vsg.group_id = any($1);
  EOQ

  param "vpc_security_group_ids" {}
}
