dashboard "aws_ec2_instance_public_access_report" {

  title = "AWS EC2 Instance Public Access Report"

  tags = merge(local.ec2_common_tags, {
    type     = "Report"
    category = "Public Access"
  })

  container {

    card {
      sql   = query.aws_ec2_instance_count.sql
      width = 2
    }

    card {
      sql   = query.aws_ec2_instance_public_access_count.sql
      width = 2
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    sql = query.aws_ec2_instance_public_access_table.sql
  }

}

query "aws_ec2_instance_public_access_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Public Instances' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_ec2_instance
    where
      public_ip_address is not null;
  EOQ
}

query "aws_ec2_instance_public_access_table" {
  sql = <<-EOQ
    select
      v.tags ->> 'Name' as "Name",
      v.instance_id as "Instance ID",
      case when public_ip_address is null then 'Private' else 'Public' end as "Public/Private",
      a.title as "Account",
      v.account_id as "Account ID",
      v.region as "Region",
      v.arn as "ARN"
    from
      aws_ec2_instance as v,
      aws_account as a
    where
      v.account_id = a.account_id;
  EOQ
}