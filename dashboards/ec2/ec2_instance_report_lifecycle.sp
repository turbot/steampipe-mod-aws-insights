query "aws_ec2_stopped_instance_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Stopped Instance' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_ec2_instance
    where
      instance_state = 'stopped';
  EOQ
}

dashboard "aws_ec2_instance_lifecycle_report" {

  title = "AWS EC2 Instance Lifecycle Report"

  tags = merge(local.ec2_common_tags, {
    type     = "Report"
    category = "Lifecycle"
  })

  container {

    card {
      sql   = query.aws_ec2_instance_count.sql
      width = 2
    }

    card {
      sql   = query.aws_ec2_stopped_instance_count.sql
      width = 2
    }

  }

  table {
    sql = <<-EOQ
      select
        tags ->> 'Name' as "Name",
        instance_id as "Instance ID",
        instance_state as "State",
        instance_lifecycle as "Lifecycle",
        account_id as "Account",
        region as "Region",
        arn as "ARN"
      from
        aws_ec2_instance;
    EOQ
  }

}
