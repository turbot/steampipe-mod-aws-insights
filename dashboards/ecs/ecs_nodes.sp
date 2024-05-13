node "ecs_cluster" {
  category = category.ecs_cluster

  sql = <<-EOQ
  select
      cluster_arn as id,
      title as title,
      jsonb_build_object(
        'ARN', cluster_arn,
        'Status', status,
        'Account ID', account_id,
        'Region', region,
        'Active Services Count', active_services_count,
        'Running Tasks Count', running_tasks_count
      ) as properties
    from
      aws_ecs_cluster
      join unnest($1::text[]) as a on cluster_arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "ecs_cluster_arns" {}
}

node "ecs_cluster_ec2_launch_type" {
  category = category.ecs_cluster_launch_type

  sql = <<-EOQ
    with list_all_task_definitions as (
      select
        distinct task_definition_arn as task_definition
      from
        aws_ecs_task
      where
        cluster_arn = any($1)
      union
      select
        distinct task_definition as task_definition
      from
        aws_ecs_service
      where
        cluster_arn = any($1)
    ),task_definition_launch_type as (
      select
        jsonb_array_elements_text(requires_compatibilities) as launch_type,
        task_definition_arn
      from
        aws_ecs_task_definition as d
      where
        d.task_definition_arn in (select task_definition from list_all_task_definitions)
    ) select
      'EC2' as id,
      'EC2' as title,
      'ec2_launch_type' as category,
      jsonb_build_object(
        'Launch Type', 'EC2'
      ) as properties
    from
      aws_ecs_cluster
    where
      'EC2' in (
        select
          launch_type
        from
          task_definition_launch_type
      )
      and cluster_arn = any($1);
  EOQ

  param "ecs_cluster_arns" {}
}

node "ecs_cluster_external_launch_type" {
  # category = category.fargate_launch_type

  sql = <<-EOQ
    with list_all_task_definitions as (
      select
        distinct task_definition_arn as task_definition
      from
        aws_ecs_task
      where
        cluster_arn = any($1)
      union
      select
        distinct task_definition as task_definition
      from
        aws_ecs_service
      where
        cluster_arn = any($1)
    ),task_definition_launch_type as (
      select
        jsonb_array_elements_text(requires_compatibilities) as launch_type,
        task_definition_arn
      from
        aws_ecs_task_definition as d
      where
        d.task_definition_arn in (select task_definition from list_all_task_definitions)
    ) select
        'EXTERNAL' as id,
        'EXTERNAL' as title,
        jsonb_build_object(
          'Launch Type', 'EXTERNAL'
        ) as properties
      from
        aws_ecs_cluster
      where
        'EXTERNAL' in (
          select
            launch_type
          from
            task_definition_launch_type
        )
        and cluster_arn = any($1);
  EOQ

  param "ecs_cluster_arns" {}
}

node "ecs_cluster_fargate_launch_type" {
  category = category.ecs_cluster_launch_type

  sql = <<-EOQ
    with list_all_task_definitions as (
      select
        distinct task_definition_arn as task_definition
      from
        aws_ecs_task
      where
        cluster_arn = any($1)
      union
      select
        distinct task_definition as task_definition
      from
        aws_ecs_service
      where
        cluster_arn = any($1)
    ),task_definition_launch_type as (
      select
        jsonb_array_elements_text(requires_compatibilities) as launch_type,
        task_definition_arn
      from
        aws_ecs_task_definition as d
      where
        d.task_definition_arn in (select task_definition from list_all_task_definitions)
    ) select
        'FARGATE' as id,
        'FARGATE' as title,
        jsonb_build_object(
          'Launch Type', 'FARGATE'
        ) as properties
      from
        aws_ecs_cluster
      where
        'FARGATE' in (
          select
            launch_type
          from
            task_definition_launch_type
        )
        and cluster_arn = any($1);
  EOQ

  param "ecs_cluster_arns" {}
}

node "ecs_container_instance" {
  category = category.ecs_container_instance

  sql = <<-EOQ
    select
      i.arn as id,
      i.title as title,
      jsonb_build_object(
        'ARN', i.arn,
        'Instance ID', i.ec2_instance_id,
        'Status', i.status,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_ecs_container_instance as i
      join unnest($1::text[]) as a on i.arn = a and i.account_id = split_part(a, ':', 5) and i.region = split_part(a, ':', 4);
  EOQ

  param "ecs_container_instance_arns" {}
}

node "ecs_service" {
  category = category.ecs_service

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Status', status,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ecs_service
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "ecs_service_arns" {}
}

node "ecs_task" {
  category = category.ecs_task

  sql = <<-EOQ
    select
      t.task_arn as id,
      concat(split_part(t.task_arn, '/', 2),'/' ,split_part(t.task_arn, '/', 3)) as title,
      jsonb_build_object(
        'ARN', t.task_arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_ecs_task as t
      join unnest($1::text[]) as a on t.task_arn = a and t.account_id = split_part(a, ':', 5) and t.region = split_part(a, ':', 4);
  EOQ

  param "ecs_task_arns" {}
}

node "ecs_task_definition" {
  category = category.ecs_task_definition

  sql = <<-EOQ
    select
      task_definition_arn as id,
      title as title,
      jsonb_build_object(
        'ARN', task_definition_arn,
        'Status', status,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ecs_task_definition
      join unnest($1::text[]) as a on task_definition_arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "ecs_task_definition_arns" {}
}
