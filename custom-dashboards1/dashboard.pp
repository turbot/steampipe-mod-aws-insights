dashboard "custom_dashboard" {
  title = "custom dashboard"
  container {
    title = "EC2"
    card {
      query = query.custom_ec2_instance_count
      width = 2
    }
    chart {
      title = "Public/Private IP"
      query = query.custom_ec2_instance_by_public_ip
      type  = "donut"
      width = 4
      series "count" {
        point "private IP" {
          color = "ok"
        }
        point "public IP" {
          color = "alert"
        }
      }
    }

    #chart {
    #  width = 6
    #  title = "EC2 Compute Monthly Unblended Cost"
    #  type  = "column"
    #  query = query.ec2_instance_unblended_cost_per_month
    #}
    table{
      title = "List of EC2 Instances in Stop State for More Than 30 Days"
      width = 4
      query = query.custom_ec2_instance_stopped_month
    }
    table{
      title = "List of EC2 Instance not Associated with any Instance Profile"
      width = 6
      query = query.custom_ec2_instance_no_instance_profile
    } 
  }
  #EBS Volume
  container{
    title = "EBS Volume"
    card {
      query = query.custom_ebs_volume_count
      width = 2
    }
    table {
      width = 4
      title = "Unattached EBS volumes Details"
      query = query.custom_ebs_volume_details
    } 
    chart {
      title = "Volumes by Type"
      query = query.custom_ebs_volume_by_type
      type  = "donut"
      width = 3 
      series "volumes" {
        point "gp2" {
          color = "alert"
        }
        point "gp3" {
          color = "ok"
        } 
      }  
    }
    chart {
      title = "Volume State"
      query = query.custom_ebs_volume_by_state
      type  = "donut"
      width = 3
      series "count" {
        point "in-use" {
          color = "ok"
        }
        point "available" {
          color = "alert"
        } 
      } 
    }
  }
  #Security Groups
  container {
    title = "Security Groups"
    card {
      query = query.custom_vpc_security_group_count
      width = 3
    }
    card {
      query = query.custom_vpc_security_group_unassociated_count
      width = 3
    }
    table {
      width = 6
      title = "List of Unassociated Security Groups"
      query = query.custom_vpc_security_group_unassociated_list
    }
    table {
      width = 4
      title = "Unrestricted SSH/RDP Access List"
      query = query.custom_vpc_security_group_unrestricted_ssh_rdp
    }
  }
  #S3 Bucket  
  container {
    title = "S3 Bucket"
    card {
      query = query.custom_s3_bucket_count
      width = 2
    }
    chart {
      title = "Public Access Blocked"
      query = query.custom_s3_bucket_public_access_blocked
      type  = "donut"
      width = 4
      series "count" {
        point "blocked" {
          color = "ok"
        }
        point "not blocked" {
          color = "alert"
        }
      }
    }
    chart {
      title = "Versioning Status"
      query = query.custom_s3_bucket_versioning_status
      type  = "donut"
      width = 4
      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }
  }
  #EKS Cluster
  container{
    title = "EKS Cluster"
    card {
      query = query.custom_eks_cluster_count
      width = 3
    }
    card {
      query = query.custom_eks_cluster_endpoint_endpoint_public_access_disabled
      width = 3
    }
  }
  #RDS DB Instances
  container{
    title = "RDS DB Instance"
    card {
      query = query.custom_rds_db_instance_count
      width = 2
    }
    chart {
      title = "Public/Private Status"
      query = query.custom_rds_db_instance_public_status
      type  = "donut"
      width = 4
      series "count" {
        point "private" {
          color = "ok"
        }
        point "public" {
          color = "alert"
        }
      }
    }
    chart {
      title = "Deletion Protection Status"
      query = query.custom_rds_db_instance_deletion_protection_status
      type  = "donut"
      width = 4
      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }
  }
    
  #Application Load Balancer
  container{
    title = "Application Load Balancer"
    card {
      query = query.custom_ec2_application_load_balancer_count
      width = 2
    }
    chart {
       title = "Scheme"
       width = 4
       query = query.custom_ec2_application_load_balancer_scheme
       type = "column"
    }
  }
  #Cloudwatch Alarms
  container{
    title = "CloudWatch"
    card{
      query = query.custom_cloudwatch_count
      width = 2
    }
    table {
      width = 8
      title = "In alarm State"
      query = query.custom_cloudwatch_inalarm
    }
  }
  #Elasticache
  container{
    title = "Elasticache"  
    card{
      query = query.custom_elasticache_count
      width = 2
    }  
    table {
      width = 4
      title = "Clusters whose available zone count is less than 2"
      query = query.custom_elasticache_az 
   }
   chart {
     title = "Automatic Backup Status"
     query = query.custom_elasticache_automated_backup_enabled
     type  = "donut"
     width = 4
     series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }
  }
  #IAM Users
  container{
    title = "IAM User"
    card{
      query = query.custom_iam_users_count
      width = 2
    }
    table{
      title = "List of IAM Users With Administrator Access"
      query = query.custom_iam_users_admin_acccess
      width = 6
    }
  }
}
#EC2 Instance
query "custom_ec2_instance_count" {
  sql = <<-EOQ
    select count(*) as "Instances" from aws_ec2_instance
  EOQ
}
query "custom_ec2_instance_by_public_ip" {
  sql = <<-EOQ
    with instances as (
      select
        case
          when public_ip_address is null then 'private IP'
          else 'public IP'
        end as visibility
      from
        aws_ec2_instance
    )
    select
      visibility,
      count(*)
    from
      instances
    group by
      visibility
  EOQ
}

#query "ec2_instance_unblended_cost_per_month" {
#  sql = <<-EOQ
#    select
#      to_char(period_start, 'Mon-YY') as "Month",
#      sum(unblended_cost_amount)::numeric as "Unblended Cost"
#    from
#      aws_cost_by_service_usage_type_monthly
#    where
#      service = 'Amazon Elastic Compute Cloud - Compute'
#    group by
#      period_start
#    order by
#      period_start
#  EOQ
#}
query "custom_ec2_instance_stopped_month" {
  sql = <<-EOQ
    select
  instance_id,
  instance_state,
  launch_time,
  state_transition_time
from
  aws_ec2_instance
where
  instance_state = 'stopped'
  and state_transition_time <= (current_date - interval '30' day);
  EOQ
}
query "custom_ec2_instance_no_instance_profile" {
  sql = <<-EOQ
    SELECT
  instance_id,
  title
FROM
  aws_ec2_instance
WHERE
  iam_instance_profile_id IS NULL;
  EOQ
}
#EBS Volumes
query "custom_ebs_volume_by_type" {
  sql = <<-EOQ
    select
      volume_type as "Type",
      count(*) as "volumes"
    from
      aws_ebs_volume
    group by
      volume_type
    order by
      volume_type;
  EOQ
}

query "custom_ebs_volume_by_state" {
  sql = <<-EOQ
    select
      state,
      count(state)
    from
      aws_ebs_volume
    group by
      state;
  EOQ
}
query "custom_ebs_volume_count" {
  sql = <<-EOQ
    select
      count(*) as "Volumes"
    from
      aws_ebs_volume;
  EOQ
}
query "custom_ebs_volume_details" {
  sql = <<-EOQ
  select 
  volume_id,
  volume_type
from 
  aws_ebs_volume
where
  jsonb_array_length(attachments) = 0 limit 10;
    

EOQ
}

#Number of Security groups
query "custom_vpc_security_group_count" {
  sql = <<-EOQ
    select count(*) as "Security Groups" from aws_vpc_security_group;
  EOQ
}
#Number of unassociated security groups

query "custom_vpc_security_group_unassociated_count" {
  sql = <<-EOQ
    with associated_sg as (
      select
        sg ->> 'GroupId' as sg_id,
        sg ->> 'GroupName' as sg_name
        
      from
        aws_ec2_network_interface,
        jsonb_array_elements(groups) as sg
    )
    select
      count(*) as value,
      'Unassociated' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_vpc_security_group s
      left join associated_sg a on s.group_id = a.sg_id
    where
      a.sg_id is null;
  EOQ
}
query "custom_vpc_security_group_unassociated_list" {
  sql = <<-EOQ
    with associated_sg as (
  select
    sg ->> 'GroupId' as sg_id,
    sg ->> 'GroupName' as sg_name
    
  from
    aws_ec2_network_interface,
    jsonb_array_elements(groups) as sg
)
select
  group_id, group_name
from
  aws_vpc_security_group s
  left join associated_sg a on s.group_id = a.sg_id
where
  a.sg_id is null;
  EOQ
}
#SGs with unrestricted ssh & RDP access from internet
query "custom_vpc_security_group_unrestricted_ssh_rdp" {
  sql = <<-EOQ
  select
  sg.group_name,
  sg.group_id,
  sgr.type,
  sgr.ip_protocol,
  sgr.from_port,
  sgr.to_port,
  cidr_ip
from
  aws_vpc_security_group as sg
  join aws_vpc_security_group_rule as sgr on sg.group_name = sgr.group_name
where
  sgr.type = 'ingress'
  and sgr.cidr_ip = '0.0.0.0/0'
  and (
    (
      sgr.ip_protocol = '-1' -- all traffic
      and sgr.from_port is null
    )
    or (
      sgr.from_port <= 22
      and sgr.to_port >= 22
    )
    or (
      sgr.from_port <= 3389
      and sgr.to_port >= 3389
    )
  );
  EOQ
}
#Number of s3 buckets
query "custom_s3_bucket_count" {
  sql = <<-EOQ
    select count(*) as "Buckets" from aws_s3_bucket;
  EOQ
}
#S3 buckets with public access
query "custom_s3_bucket_public_access_blocked" {
  sql = <<-EOQ
    with public_block_status as (
      select
        case
          when
            block_public_acls
            and block_public_policy
            and ignore_public_acls
            and restrict_public_buckets
          then 'blocked' else 'not blocked'
        end as block_status
      from
        aws_s3_bucket
    )
    select
      block_status,
      count(*)
    from
      public_block_status
    group by
      block_status;
  EOQ
}
query "custom_s3_bucket_versioning_status" {
  sql = <<-EOQ
    with versioning_status as (
      select
        case
          when versioning_enabled then 'enabled' else 'disabled'
        end as visibility
      from
        aws_s3_bucket
    )
    select
      visibility,
      count(*)
    from
      versioning_status
    group by
      visibility;
  EOQ
}

query "custom_eks_cluster_count" {
  sql = <<-EOQ
    select
      count(*) as "Clusters"
    from
      aws_eks_cluster;
  EOQ
}
query "custom_eks_cluster_endpoint_endpoint_public_access_disabled" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Endpoint Public Access Disabled' as label,
      case count(*) when 0 then 'alert' else 'ok' end as "type"
    from
      aws_eks_cluster
    where
      resources_vpc_config -> 'EndpointPublicAccess' = 'true';
  EOQ
}
#RDS DB Instance 
query "custom_rds_db_instance_count" {
  sql = <<-EOQ
    select count(*) as "RDS DB Instances" from aws_rds_db_instance
  EOQ
}
query "custom_rds_db_instance_public_status" {
  sql = <<-EOQ
    with db_instances as (
      select
        case
          when publicly_accessible is null or (not publicly_accessible) then 'private'
          else 'public'
        end as visibility
      from
        aws_rds_db_instance
    )
    select
      visibility,
      count(*)
    from
      db_instances
    group by
      visibility;
  EOQ
}
query "custom_rds_db_instance_deletion_protection_status" {
  sql = <<-EOQ
    with db_instances as (
      select
        case
          when deletion_protection then 'enabled'
          else 'disabled'
        end as visibility
      from
        aws_rds_db_instance
    )
    select
      visibility,
      count(*)
    from
      db_instances
    group by
      visibility;
  EOQ
}
#Application Load Balancer
query "custom_ec2_application_load_balancer_count" {
  sql = <<-EOQ
    select count(*) as "Application Load Balancers" from aws_ec2_application_load_balancer;
  EOQ
}
query "custom_ec2_application_load_balancer_scheme"{
  sql = <<-EOQ
    SELECT scheme as "Scheme",
       count(*) as "albs_count" from aws_ec2_application_load_balancer group by scheme order by scheme;
EOQ
}
#CloudWatch Alarms
query "custom_cloudwatch_count"{
  sql = <<-EOQ
    select count(*) as "CloudWatch Alarms" from aws_cloudwatch_alarm;
EOQ 
 }
query "custom_cloudwatch_inalarm"{
  sql = <<-EOQ
  select
  name,
  arn,
  state_value,
  state_reason
from
  aws_cloudwatch_alarm
where
  state_value = 'ALARM';
EOQ
}
#Elasticache
query "custom_elasticache_count"{
  sql = <<-EOQ
  select count(*) as "Caches" from aws_elasticache_cluster;
  EOQ
}
query "custom_elasticache_az"{
sql = <<-EOQ
  select
  cache_cluster_id,
  preferred_availability_zone
from
  aws_elasticache_cluster
where
  preferred_availability_zone <> 'Multiple';
  EOQ
}
query "custom_elasticache_automated_backup_enabled"{
sql = <<-EOQ
  
      select
  automatic_backup_status,
  count(*)
from
  (
    select
      snapshot_retention_limit,
      case
        when snapshot_retention_limit is not null then 'enabled'
        else 'disabled'
      end automatic_backup_status
    from
      aws_elasticache_cluster
  ) as a
group by
  automatic_backup_status
order by
  automatic_backup_status desc;
EOQ
}
#IAM Users
query "custom_iam_users_count"{
  sql = <<-EOQ
  select count(*) as "IAM Users" from aws_iam_user;
  EOQ
}
query "custom_iam_users_admin_acccess"{
  sql = <<-EOQ
  select
  name as user_name,
  split_part(attachments, '/', 2) as attached_policies
from
  aws_iam_user
  cross join jsonb_array_elements_text(attached_policy_arns) as attachments
where
  split_part(attachments, '/', 2) = 'AdministratorAccess';
  EOQ
}
