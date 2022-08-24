dashboard "aws_ecs_cluster_detail" {

  title         = "AWS ECS Cluster Detail"
  documentation = file("./dashboards/ecs/docs/ecs_cluster_detail.md")

  tags = merge(local.ecs_common_tags, {
    type = "Detail"
  })

  input "ecs_cluster_arn" {
    title = "Select a cluster:"
    sql   = query.aws_ecs_cluster_input.sql
    width = 4
  }

  container {

    card {
      query = query.aws_ecs_cluster_status
      width = 2
      args = {
        arn = self.input.ecs_cluster_arn.value
      }
    }

    card {
      query = query.aws_ecs_cluster_registered_container_instances_count
      width = 2
      args = {
        arn = self.input.ecs_cluster_arn.value
      }
    }

    card {
      query = query.aws_ecs_cluster_pending_tasks_count
      width = 2
      args = {
        arn = self.input.ecs_cluster_arn.value
      }
    }

    card {
      query = query.aws_ecs_cluster_running_tasks_count
      width = 2
      args = {
        arn = self.input.ecs_cluster_arn.value
      }
    }

    card {
      query = query.aws_ecs_cluster_active_services_count
      width = 2
      args = {
        arn = self.input.ecs_cluster_arn.value
      }
    }

  }

  container {

    graph {
      type  = "graph"
      title = "Relationships"
      query = query.aws_ecs_cluster_relationships_graph
      args = {
        arn = self.input.ecs_cluster_arn.value
      }

      category "aws_ecs_task" {
        icon       = local.aws_ecs_task_icon
        fold {
        threshold  = 3
        title      = "Tasks..."

        }
      }

      category "aws_vpc" {
        href = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.'VPC ID' | @uri}}"
        icon = local.aws_vpc_icon
      }

      category "aws_ecs_container_instance" {
        color = "green"
      }

      category "aws_ecs_service" {
        icon = local.aws_ecs_service_icon
      }

      category "aws_kms_key" {
        href = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.ARN | @uri}}"
        icon = local.aws_kms_key_icon
      }

      category "aws_kinesis_stream" {
        icon = local.aws_kinesis_stream_icon
      }

      category "aws_s3_bucket" {
        href = "${dashboard.aws_s3_bucket_detail.url_path}?input.key_arn={{.properties.ARN | @uri}}"
        icon = local.aws_s3_bucket_icon
      }

      category "uses" {
        color = "green"
      }
    }

  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.aws_ecs_cluster_overview
        args = {
          arn = self.input.ecs_cluster_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_ecs_cluster_tags
        args = {
          arn = self.input.ecs_cluster_arn.value
        }

      }
    }

    container {
      width = 6

    }

  }
}

query "aws_ecs_cluster_input" {
  sql = <<-EOQ
    select
      title as label,
      cluster_arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'cluster_arn', cluster_arn
      ) as tags
    from
      aws_ecs_cluster
    order by
      title;
  EOQ
}

query "aws_ecs_cluster_status" {
  sql = <<-EOQ
    select
      initcap(status) as value,
      'Status' as label
    from
      aws_ecs_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecs_cluster_registered_container_instances_count" {
  sql = <<-EOQ
    select
      registered_container_instances_count as value,
      'Registered Container Instances' as label
    from
      aws_ecs_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecs_cluster_pending_tasks_count" {
  sql = <<-EOQ
    select
      pending_tasks_count as value,
      'Pending Tasks' as label
    from
      aws_ecs_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecs_cluster_running_tasks_count" {
  sql = <<-EOQ
    select
      running_tasks_count as value,
      'Running Tasks' as label
    from
      aws_ecs_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecs_cluster_active_services_count" {
  sql = <<-EOQ
    select
      active_services_count as value,
      'Active Services' as label
    from
      aws_ecs_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecs_cluster_overview" {
  sql = <<-EOQ
    select
      cluster_name as "Name",
      region as "Region",
      account_id as "Account ID",
      cluster_arn as "ARN"
    from
      aws_ecs_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecs_cluster_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_ecs_cluster,
      jsonb_array_elements(tags_src) as tag
    where
      cluster_arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "aws_ecs_cluster_relationships_graph" {
  sql = <<-EOQ
    with esc_cluster as (
      select
        *
      from
        aws_ecs_cluster
      where
        cluster_arn = $1
    )
    select
      null as from_id,
      null as to_id,
      cluster_arn as id,
      cluster_name as title,
      'aws_ecs_cluster' as category,
      jsonb_build_object(
        'ARN', cluster_arn,
        'Status', status,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      esc_cluster

    -- To ECS conatiner instances (node)
    union all
    select
      null as from_id,
      null as to_id,
      i.arn as id,
      e.title as title,
      'aws_ecs_container_instance' as category,
      jsonb_build_object(
        'ARN', i.arn,
        'Instance ID', i.ec2_instance_id,
        'Status', i.status,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_ecs_container_instance as i
      left join aws_ec2_instance as e on i.ec2_instance_id = e.instance_id
    where
      i.cluster_arn = $1

    -- To ECS conatiner instances (edge)
    union all
    select
      $1 as from_id,
      i.arn as to_id,
      null as id,
      'uses' as title,
      'ecs_cluster_to_ecs_container_insatnce' as category,
      jsonb_build_object(
        'ARN', i.arn,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_ecs_container_instance as i
      left join aws_ec2_instance as e on i.ec2_instance_id = e.instance_id
    where
      i.cluster_arn = $1

    -- To VPC Subnet (node)
    union all
    select
      null as from_id,
      null as to_id,
      s.subnet_arn as id,
      s.title as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'ARN', s.subnet_arn,
        'Subnet ID', s.subnet_id,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_ecs_container_instance as i
      right join aws_ec2_instance as c on c.instance_id = i.ec2_instance_id
      right join aws_vpc_subnet as s on s.subnet_id = c.subnet_id
    where
      i.cluster_arn  = $1

    -- To VPC Subnet  (edge)
    union all
    select
      i.arn as from_id,
      s.subnet_arn as to_id,
      null as id,
      'subnet' as title,
      'ecs_container_instance_to_vpc_subnet' as category,
      jsonb_build_object(
        'ARN', s.subnet_arn,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_ecs_container_instance as i
      right join aws_ec2_instance as c on c.instance_id = i.ec2_instance_id
      right join aws_vpc_subnet as s on s.subnet_id = c.subnet_id
    where
      i.cluster_arn  = $1

    -- To VPC  (node)
    union all
    select
      null as from_id,
      null as to_id,
      v.vpc_id as id,
      v.title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'ARN', v.arn,
        'ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      aws_ecs_container_instance as i
      right join aws_ec2_instance as c on c.instance_id = i.ec2_instance_id
      right join aws_vpc_subnet as s on s.subnet_id = c.subnet_id
      right join aws_vpc as v on v.vpc_id = s.vpc_id
    where
      i.cluster_arn  = $1

    -- To VPC  (edge)
    union all
    select
      s.subnet_arn as from_id,
      v.vpc_id as to_id,
      null as id,
      'vpc' as title,
      'vpc_subnet_to_vpc' as category,
      jsonb_build_object(
        'ARN', v.arn,
        'ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      aws_ecs_container_instance as i
      right join aws_ec2_instance as c on c.instance_id = i.ec2_instance_id
      right join aws_vpc_subnet as s on s.subnet_id = c.subnet_id
      right join aws_vpc as v on v.vpc_id = s.vpc_id
    where
      i.cluster_arn  = $1

    -- To ECS task (node)
    union all
    select
      null as from_id,
      null as to_id,
      t.task_arn as id,
      concat(split_part(t.task_arn, '/', 2),'/' ,split_part(t.task_arn, '/', 3)) as title,
      'aws_ecs_task' as category,
      jsonb_build_object(
        'ARN', t.task_arn,
        'launch_type', t.launch_type,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_ecs_task as t
    where
      t.launch_type = 'EC2'
      and t.cluster_arn = $1

    -- To ECS task (edge)
    union all
    select
      t.container_instance_arn as from_id,
      t.task_arn as to_id,
      null as id,
      'task' as title,
      'aws_ecs_task' as category,
      jsonb_build_object(
        'ARN', t.task_arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_ecs_task as t
    where
      t.launch_type = 'EC2'
      and t.cluster_arn = $1

  -- To ECS service launch type = ec2 (node)
    union all
    select
      null as from_id,
      null as to_id,
      s.arn as id,
      s.service_name as title,
      'aws_ecs_service' as category,
      jsonb_build_object(
        'ARN', s.arn,
        'launch_type', s.launch_type,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_ecs_service as s
    where
      s.launch_type = 'EC2'
      and s.cluster_arn = $1

    -- To ECS service launch type = ec2 (edge)
    union all
    select
      i.arn as from_id,
      s.arn as to_id,
      null as id,
      'service' as title,
      'aws_ecs_service' as category,
      jsonb_build_object(
        'ARN', s.arn,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_ecs_service as s
      left join aws_ecs_container_instance as i on i.cluster_arn = s.cluster_arn
    where
      s.launch_type = 'EC2'
      and s.cluster_arn = $1

   -- To ECS task launch type <> ec2 (node)
    union all
    select
      null as from_id,
      null as to_id,
      t.task_arn as id,
      concat(split_part(t.task_arn, '/', 2),'/' ,split_part(t.task_arn, '/', 3)) as title,
      'aws_ecs_task' as category,
      jsonb_build_object(
        'ARN', t.task_arn,
        'launch_type', t.launch_type,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_ecs_task as t
    where
      t.launch_type <> 'EC2'
      and t.cluster_arn = $1

    -- To ECS task launch type <> ec2 (edge)
    union all
    select
      t.cluster_arn as from_id,
      t.task_arn as to_id,
      null as id,
      'task' as title,
      'aws_ecs_task' as category,
      jsonb_build_object(
        'ARN', t.task_arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_ecs_task as t
    where
      t.launch_type <> 'EC2'
      and t.cluster_arn = $1

    -- To ECS service launch type <> ec2 (node)
    union all
    select
      null as from_id,
      null as to_id,
      s.arn as id,
      s.service_name as title,
      'aws_ecs_service' as category,
      jsonb_build_object(
        'ARN', s.arn,
        'launch_type', s.launch_type,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_ecs_service as s
    where
      s.launch_type <> 'EC2'
      and s.cluster_arn = $1

    -- To ECS service launch type <> ec2 (edge)
    union all
    select
      s.cluster_arn as from_id,
      s.arn as to_id,
      null as id,
      'service' as title,
      'aws_ecs_service' as category,
      jsonb_build_object(
        'ARN', s.arn,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_ecs_service as s
    where
      s.launch_type <> 'EC2'
      and s.cluster_arn = $1

    -- To ECS task definition for task (node)
    union all
    select
      null as from_id,
      null as to_id,
      d.task_definition_arn as id,
      d.title as title,
      'aws_ecs_task_definition' as category,
      jsonb_build_object(
        'ARN', d.task_definition_arn,
        'Account ID', d.account_id,
        'Region', d.region
      ) as properties
    from
      aws_ecs_task as t
      right join aws_ecs_task_definition as d on d.task_definition_arn =  t.task_definition_arn
    where
      t.cluster_arn = $1

    -- To ECS task definition (edge)
    union all
    select
      t.task_arn as from_id,
      d.task_definition_arn as to_id,
      null as id,
      'task defintion' as title,
      'aws_ecs_task_definition' as category,
      jsonb_build_object(
        'ARN', d.task_definition_arn,
        'Account ID', d.account_id,
        'Region', d.region
      ) as properties
    from
      aws_ecs_task as t
      right join aws_ecs_task_definition as d on d.task_definition_arn =  t.task_definition_arn
    where
      t.cluster_arn = $1

    -- To ECS task definition for servcie (node)
    union all
    select
      null as from_id,
      null as to_id,
      d.task_definition_arn as id,
      d.title as title,
      'aws_ecs_task_definition' as category,
      jsonb_build_object(
        'ARN', d.task_definition_arn,
        'Account ID', d.account_id,
        'Region', d.region
      ) as properties
    from
      aws_ecs_service as s
      right join aws_ecs_task_definition as d on d.task_definition_arn =  s.task_definition
    where
      s.cluster_arn = $1

    -- To ECS task definition servcie (edge)
    union all
    select
      s.arn as from_id,
      d.task_definition_arn as to_id,
      null as id,
      'task defintion' as title,
      'aws_ecs_task_definition' as category,
      jsonb_build_object(
        'ARN', d.task_definition_arn,
        'Account ID', d.account_id,
        'Region', d.region
      ) as properties
    from
      aws_ecs_service as s
      right join aws_ecs_task_definition as d on d.task_definition_arn =  s.task_definition
    where
      s.cluster_arn = $1
  EOQ

  param "arn" {}
}
