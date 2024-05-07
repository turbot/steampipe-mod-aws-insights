edge "ecs_cluster_to_ec2_instance" {
  title = "container instance"

  sql = <<-EOQ
    select
      distinct cluster.cluster_arn as from_id,
      i.arn as to_id
    from
      aws_ec2_instance as i,
      aws_ecs_container_instance as ci,
      aws_ecs_cluster as cluster
    where
      ci.ec2_instance_id = i.instance_id
      and ci.cluster_arn = cluster.cluster_arn
      and i.arn = any($1);
  EOQ

  param "ec2_instance_arns" {}
}

edge "ecs_cluster_to_ecs_cluster_ec2_launch_type" {
  title = "launch type"

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
        cluster_arn as from_id,
        'EC2' as to_id
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

edge "ecs_cluster_to_ecs_cluster_external_launch_type" {
  title = "launch type"

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
        cluster_arn as from_id,
        'EXTERNAL' as to_id
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

edge "ecs_cluster_to_ecs_cluster_fargate_launch_type" {
  title = "launch type"

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
        cluster_arn as from_id,
        'FARGATE' as to_id
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

edge "ecs_cluster_to_ecs_container_instance" {
  title = "container instance"

  sql = <<-EOQ
    select
      'EC2' as from_id,
      i.arn as to_id
    from
      aws_ecs_container_instance as i
      join unnest($1::text[]) as a on i.cluster_arn = a and i.account_id = split_part(a, ':', 5) and i.region = split_part(a, ':', 4);
  EOQ

  param "ecs_cluster_arns" {}
}

edge "ecs_cluster_to_ecs_service" {
  title = "ecs service"

  sql = <<-EOQ
    select
      cluster_arn as from_id,
      arn to_id
    from
      aws_ecs_service
      join unnest($1::text[]) as a on cluster_arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "ecs_cluster_arns" {}
}

edge "ecs_cluster_to_ecs_task_definition" {
  title = "task defintion"

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
    )
    select
      jsonb_array_elements_text(requires_compatibilities) as from_id,
      d.task_definition_arn as to_id
    from
      aws_ecs_task_definition as d
    where
      d.task_definition_arn in (
        select
          task_definition
        from
          list_all_task_definitions
      );
  EOQ

  param "ecs_cluster_arns" {}
}

edge "ecs_container_instance_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      i.arn as from_id,
      c.subnet_id as to_id
    from
      aws_ecs_container_instance as i
      join unnest($1::text[]) as a on i.arn = a and i.account_id = split_part(a, ':', 5) and i.region = split_part(a, ':', 4)
      right join aws_ec2_instance as c on c.instance_id = i.ec2_instance_id;
  EOQ

  param "ecs_container_instance_arns" {}
}

edge "ecs_service_to_ec2_target_group" {
  title = "target group"

  sql = <<-EOQ
    select
      s.arn as from_id,
      l ->> 'TargetGroupArn' as to_id
    from
      aws_ecs_service as s
      join unnest($1::text[]) as a on s.arn = a and s.account_id = split_part(a, ':', 5) and s.region = split_part(a, ':', 4),
      jsonb_array_elements(load_balancers) as l
      left join aws_ec2_target_group as t on t.target_group_arn = l ->> 'TargetGroupArn';
  EOQ

  param "ecs_service_arns" {}
}

edge "ecs_service_to_ecs_container_instance" {
  title = "container instance"

  sql = <<-EOQ
    select
      s.arn as from_id,
      i.arn as to_id
    from
      aws_ecs_service as s
      join unnest($1::text[]) as a on s.arn = a and s.account_id = split_part(a, ':', 5) and s.region = split_part(a, ':', 4)
      left join aws_ecs_container_instance as i on s.cluster_arn = i.cluster_arn
      left join aws_ec2_instance as e on i.ec2_instance_id = e.instance_id;
  EOQ

  param "ecs_service_arns" {}
}

edge "ecs_task_definition_to_ecs_task" {
  title = "task"

  sql = <<-EOQ
    select
      task_definition_arn as from_id,
      task_arn as to_id
    from
      aws_ecs_task
      join unnest($1::text[]) as a on task_definition_arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "ecs_task_definition_arns" {}
}

edge "ecs_service_to_ecs_task" {
  title = "task"

  sql = <<-EOQ
    select
      arn as from_id,
      task_arn as to_id
    from
      aws_ecs_service as s
      join unnest($1::text[]) as a on s.arn = a and s.account_id = split_part(a, ':', 5) and s.region = split_part(a, ':', 4),
      aws_ecs_task as t
    where
      s.task_definition = t.task_definition_arn
      and arn = any($1);
  EOQ

  param "ecs_service_arns" {}
}

edge "ecs_service_to_ecs_task_definition" {
  title = "task definition"

  sql = <<-EOQ
    select
      coalesce(task_arn, arn) as from_id,
      task_definition as to_id
    from
      aws_ecs_service as s
      join unnest($1::text[]) as a on s.arn = a and s.account_id = split_part(a, ':', 5) and s.region = split_part(a, ':', 4)
      left join aws_ecs_task as t on s.task_definition = t.task_definition_arn;
  EOQ

  param "ecs_service_arns" {}
}

edge "ecs_service_to_iam_role" {
  title = "assumes"

  sql = <<-EOQ
    select
      s.arn as from_id,
      s.role_arn as to_id
    from
      aws_ecs_service as s
      join unnest($1::text[]) as a on s.arn = a and s.account_id = split_part(a, ':', 5) and s.region = split_part(a, ':', 4)
      left join aws_iam_role as r on r.arn = s.role_arn;
  EOQ

  param "ecs_service_arns" {}
}

edge "ecs_service_to_vpc_security_group" {
  title = "security group"

  sql = <<-EOQ
    select
      e.arn as from_id,
      s as to_id
    from
      aws_ecs_service as e
      join unnest($1::text[]) as a on e.arn = a and e.account_id = split_part(a, ':', 5) and e.region = split_part(a, ':', 4),
      jsonb_array_elements_text(e.network_configuration -> 'AwsvpcConfiguration' -> 'SecurityGroups') as s
    where
      e.arn = any($1)
      and e.network_configuration is not null;
  EOQ

  param "ecs_service_arns" {}
}

edge "ecs_service_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      coalesce(sg, e.arn) as from_id,
      s as to_id
    from
      aws_ecs_service as e
      join unnest($1::text[]) as a on e.arn = a and e.account_id = split_part(a, ':', 5) and e.region = split_part(a, ':', 4)
      cross join jsonb_array_elements_text(e.network_configuration -> 'AwsvpcConfiguration' -> 'Subnets') as s
      cross join jsonb_array_elements_text(e.network_configuration -> 'AwsvpcConfiguration' -> 'SecurityGroups') as sg
    where
      e.network_configuration is not null;
  EOQ

  param "ecs_service_arns" {}
}

edge "ecs_task_definition_to_cloudwatch_log_group" {
  title = "logs to"

  sql = <<-EOQ
    select
      task_definition_arn as from_id,
      g.arn as to_id
    from
      aws_ecs_task_definition as td
      join unnest($1::text[]) as a on td.task_definition_arn = a and td.account_id = split_part(a, ':', 5) and td.region = split_part(a, ':', 4),
      jsonb_array_elements(container_definitions) as d
      left join aws_cloudwatch_log_group as g on g.name = d -> 'LogConfiguration' -> 'Options' ->> 'awslogs-group'
    where
      d -> 'LogConfiguration' -> 'Options' ->> 'awslogs-region' = g.region;
  EOQ

  param "ecs_task_definition_arns" {}
}

edge "ecs_task_definition_to_ecr_repository" {
  title = "ecr repository"

  sql = <<-EOQ
    select
      task_definition_arn as from_id,
      r.arn as to_id
    from
      aws_ecs_task_definition as td
      join unnest($1::text[]) as a on td.task_definition_arn = a and td.account_id = split_part(a, ':', 5) and td.region = split_part(a, ':', 4),
      jsonb_array_elements(container_definitions) as d
      left join aws_ecr_repository as r on r.repository_uri = split_part(d ->> 'Image', ':', 1);
  EOQ

  param "ecs_task_definition_arns" {}
}

edge "ecs_task_definition_to_ecs_service" {
  title = "service"

  sql = <<-EOQ
    select
      s.task_definition as from_id,
      s.arn as to_id
    from
      aws_ecs_service as s
      join unnest($1::text[]) as a on s.task_definition = a and s.account_id = split_part(a, ':', 5) and s.region = split_part(a, ':', 4);
  EOQ

  param "ecs_task_definition_arns" {}
}

edge "ecs_task_definition_to_efs_file_system" {
  title = "file system"

  sql = <<-EOQ
    select
      task_definition_arn as from_id,
      f.arn as to_id
    from
      aws_ecs_task_definition as td,
      jsonb_array_elements(volumes) as v
      left join aws_efs_file_system as f on f.file_system_id = v -> 'EfsVolumeConfiguration' ->> 'FileSystemId'
    where
      td.task_definition_arn = any($1);
  EOQ

  param "ecs_task_definition_arns" {}
}

edge "ecs_task_definition_to_iam_execution_role" {
  title = "assumes"

  sql = <<-EOQ
    select
      d.task_definition_arn as from_id,
      d.execution_role_arn as to_id
    from
      aws_ecs_task_definition as d
      join unnest($1::text[]) as a on d.task_definition_arn = a and d.account_id = split_part(a, ':', 5) and d.region = split_part(a, ':', 4)
      left join aws_iam_role as r on r.arn = d.execution_role_arn;
  EOQ

  param "ecs_task_definition_arns" {}
}

edge "ecs_task_definition_to_iam_task_role" {
  title = "assumes task role"

  sql = <<-EOQ
    select
      d.task_definition_arn as from_id,
      d.task_role_arn as to_id
    from
      aws_ecs_task_definition as d
      join unnest($1::text[]) as a on d.task_definition_arn = a and d.account_id = split_part(a, ':', 5) and d.region = split_part(a, ':', 4)
      left join aws_iam_role as r on r.arn = d.task_role_arn;
  EOQ

  param "ecs_task_definition_arns" {}
}

edge "ecs_task_to_ecs_task_definition" {
  title = "task definition"

  sql = <<-EOQ
    select
      task_arn as from_id,
      task_definition_arn as to_id
    from
      aws_ecs_task
      join unnest($1::text[]) as a on task_arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "ecs_task_arns" {}
}
