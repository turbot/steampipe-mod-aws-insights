dashboard "aws_ebs_volume_detail" {
  title = "AWS EBS Volume Detail"

  input "ebs_volume_id" {
    title = "Volume"
    type  = "select"
    sql   = <<-EOQ
      select
        volume_id
      from
        aws_ebs_volume;
    EOQ
    width = 2
  }

  container {

    card {
      sql   = <<-EOQ
        select
          'Storage' as label,
          size as value
        from
          aws_ebs_volume
        where
          volume_id = 'vol-0a0434e8849c44d0b';
      EOQ
      width = 2
    }

    card {
      sql = <<-EOQ
        select
          'Attached Instances' as label,
          case
            when attachments is null then 0
            else jsonb_array_length(attachments)
          end as value,
          case
            when jsonb_array_length(attachments) > 0 then 'ok'
            else 'alert'
          end as "type"
        from
          aws_ebs_volume
        where
          volume_id = 'vol-0a0434e8849c44d0b';
      EOQ
      width = 2
    }

    card {
      sql   = <<-EOQ
        select
          'IOPS' as label,
          iops as value
        from
          aws_ebs_volume
        where
          volume_id = 'vol-0a0434e8849c44d0b';
      EOQ
      width = 2
    }
  }

  container {
    title  = "Analysis"

    container {

      container {
        width = 20

        table {
          title = "Overview"

          sql   = <<-EOQ
            select
              volume_id as "Volume ID",
              volume_type as "Volume Type",
              state as "Volume State",
              encrypted as "Encrypted",
              auto_enable_io as "Auto Enabled IO",
              snapshot_id as "Snapshot ID",
              availability_zone as "Availability Zone",
              kms_key_id as "Key ID",
              title as "Title",
              region as "Region",
              account_id as "Account ID",
              arn as "ARN"
            from
              aws_ebs_volume
            where
              volume_id = 'vol-0a0434e8849c44d0b';
          EOQ
        }
      }

      container {
        width = 4

        table {
          title = "Tags"

          sql   = <<-EOQ
            select
              tag ->> 'Key' as "Key",
              tag ->> 'Value' as "Value"
            from
              aws_ebs_volume,
              jsonb_array_elements(tags_src) as tag
            where
              volume_id = 'vol-0a0434e8849c44d0b';
          EOQ
        }
      }

      table {
        title = "Associated To"
        sql   = <<-EOQ
          select
            i.instance_id,
            i.arn,
            i.instance_state,
            attachment ->> 'AttachTime' as attachment_time,
            (attachment ->> 'DeleteOnTermination')::boolean as delete_on_termination
          from
            aws_ebs_volume as v,
            jsonb_array_elements(attachments) as attachment,
            aws_ec2_instance as i
          where
            i.instance_id = attachment ->> 'InstanceId'
            and volume_id = 'vol-0a0434e8849c44d0b'
        EOQ
        width = 8
      }
    }

    container {
      width = 10

      chart {
        title = "Read throughput (Ops/s) - Last 7 days"
        type  = "line"
        width = 6
        sql   =  <<-EOQ
          select
            timestamp,
            (sum / 3600) as read_throughput_ops
          from
            aws_ebs_volume_metric_read_ops_hourly
          where
            volume_id = 'vol-0a0434e8849c44d0b'
            and timestamp >= current_date - interval '7 day'
          order by timestamp;
        EOQ
      }

      chart {
        title = "Write throughput (Ops/s) - Last 7 days"
        type  = "line"
        width = 6
        sql   =  <<-EOQ
          select
            timestamp,
            (sum / 300) as write_throughput_ops
          from
            aws_ebs_volume_metric_write_ops
          where
            volume_id = 'vol-0a0434e8849c44d0b'
            and timestamp >= current_date - interval '7 day'
          order by timestamp;
        EOQ
      }
    }
  }

}
