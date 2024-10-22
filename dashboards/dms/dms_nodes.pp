
node "dms_replication_instance" {
  category = category.dms_replication_instance

  sql = <<-EOQ
    select
      ri.arn as id,
      ri.title as title,
      jsonb_build_object(
        'ID', ri.replication_instance_identifier,
        'Allocated Storage', ri.allocated_storage,
        'Availability Zone', ri.availability_zone,
        'Engine Version', ri.engine_version,
        'Publicly Accessible', ri.publicly_accessible,
        'Account ID', ri.account_id,
        'Region', ri.region
      ) as properties
    from
      aws_dms_replication_instance as ri,
      jsonb_array_elements(ri.vpc_security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'VpcSecurityGroupId'
    where
      vsg.group_id = any($1);
  EOQ

  param "vpc_security_group_ids" {}
}
