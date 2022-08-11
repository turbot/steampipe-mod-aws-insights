dashboard "aws_redshift_cluster_relationships" {
  title = "AWS Redshift Cluster Relationships"
  #documentation = file("./dashboards/redshift/docs/redshift_cluster_relationships.md")
  tags = merge(local.redshift_common_tags, {
    type = "Relationships"
  })

  input "redshift_cluster" {
    title = "Select a cluster:"
    query = query.aws_redshift_cluster_input
    width = 4
  }

  /* graph {
    type  = "graph"
    title = "Things that use me..."
    query = query.aws_redshift_cluster_graph_use_me
    args = {
      bucket = self.input.redshift_cluster.value
    }

    category "aws_redshift_cluster" {
      href = "${dashboard.aws_redshift_cluster_detail.url_path}?input.cluster_arn={{.properties.'ARN' | @uri}}"
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ctt.svg"))
    }

    category "aws_guardduty_detector" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/guardduty.svg"))
    }
  } */

  graph {
    type  = "graph"
    title = "Things I use..."
    query = query.aws_redshift_cluster_graph_i_use
    args = {
      bucket = self.input.redshift_cluster.value
    }

    category "aws_redshift_cluster" {
      icon  = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/redshift_cluster.svg"))
      color = "orange"
      href  = "${dashboard.aws_redshift_cluster_detail.url_path}?input.cluster_arn={{.properties.'ARN' | @uri}}"
    }

    category "aws_vpc" {
      icon  = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_light.svg"))
      color = "orange"
      href  = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.'ID' | @uri}}"
    }

    category "aws_vpc_eip" {
      icon  = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_eip.svg"))
      color = "orange"
    }

    category "aws_vpc_security_group" {
      icon  = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_light.svg"))
      color = "orange"
      href  = "${dashboard.aws_vpc_security_group_detail.url_path}?input.security_group_id={{.properties.'ID' | @uri}}"
    }

    category "aws_kms_key" {
      color = "green"
      icon  = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/kms_key_light.svg"))
      href  = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.'ARN' | @uri}}"
    }

    category "aws_iam_role" {
      color = "pink"
      icon  = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/iam_role_light.svg"))
      href  = "${dashboard.aws_iam_role_detail.url_path}?input.role_arn={{.properties.'ARN' | @uri}}"
    }

    category "aws_cloudwatch_log_group" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/cwl.svg"))
    }

    category "aws_s3_bucket" {
      color = "pink"
      icon  = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/s3_bucket_light.svg"))
      href  = "${dashboard.aws_s3_bucket_detail.url_path}?input.bucket_arn={{.properties.'ARN' | @uri}}"
    }

  }

}

query "aws_redshift_cluster_graph_use_me" {
  sql = <<-EOQ
    with clusters as (select * from aws_redshift_cluster where arn = $1)
    select
      null as from_id,
      null as to_id,
      arn as id,
      db_name as title,
      'aws_redshift_cluster' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region,
        'Cluster Status', cluster_status,
        'Cluster Version', cluster_version,
        'Public', publicly_accessible::text,
        'Encrypted', encrypted::text
      ) as properties
    from
      clusters

    -- GuardDuty - nodes
    union all
    select
      null as from_id,
      null as to_id,
      detector.arn as id,
      detector.detector_id as title,
      'aws_guardduty_detector' as category,
      jsonb_build_object(
        'ARN', detector.arn,
        'Account ID', detector.account_id,
        'Region', detector.region,
        'Status', detector.status
      ) as properties
    from
      aws_guardduty_detector as detector,
      clusters as t
    where 
      detector.status = 'ENABLED'
      and detector.data_sources is not null
      and detector.data_sources -> 'CloudTrail' ->> 'Status' = 'ENABLED'
      
    -- S3 Buckets - edges
    union all
    select
      detector.arn as from_id,
      t.arn as to_id,
      null as id,
      'Uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', t.arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_guardduty_detector as detector,
      clusters as t
    where 
      detector.status = 'ENABLED'
      and detector.data_sources is not null
      and detector.data_sources -> 'CloudTrail' ->> 'Status' = 'ENABLED'
  EOQ

  param "bucket" {}
}

query "aws_redshift_cluster_graph_i_use" {
  sql = <<-EOQ
    with cluster as (select * from aws_redshift_cluster where arn = $1)

    -- cluster node
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_redshift_cluster' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region,
        'Cluster Status', cluster_status,
        'Cluster Version', cluster_version,
        'Public', publicly_accessible::text,
        'Encrypted', encrypted::text
      ) as properties
    from
      cluster

    -- VPC  Nodes
    union all
    select
      null as from_id,
      null as to_id,
      v.arn as id,
      v.title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'ARN', v.arn,
        'ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region,
        'Default', is_default::text,
        'State', state
      ) as properties
    from
      cluster as c
      left join aws_vpc as v on v.vpc_id = c.vpc_id

    -- VPC Edges
    union all
    select
      c.arn as from_id,
      v.arn as to_id,
      null as id,
      'Uses' as title,
      'Uses' as category,
      jsonb_build_object(
        'ARN', v.arn,
        'ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      cluster as c
      left join aws_vpc as v on v.vpc_id = c.vpc_id

    -- Security Group Nodes
    union all
    select
      null as from_id,
      null as to_id,
      sg.arn as id,
      sg.group_id as title,
      'aws_vpc_security_group' as category,
      jsonb_build_object(
        'ARN', sg.arn,
        'ID', sg.group_id,
        'Account ID', sg.account_id,
        'Region', sg.region,
        'Status', s ->> 'Status'
      ) as properties
    from
      cluster as c,
      jsonb_array_elements(vpc_security_groups) as s
      left join aws_vpc_security_group as sg on sg.group_id = s ->> 'VpcSecurityGroupId'

    -- Security Group Edges
    union all
    select
      c.arn as from_id,
      sg.arn as to_id,
      null as id,
      'Uses' as title,
      'Uses' as category,
      jsonb_build_object(
        'ARN', sg.arn,
        'ID', sg.group_id,
        'Account ID', sg.account_id,
        'Region', sg.region
      ) as properties
    from
      cluster as c,
      jsonb_array_elements(vpc_security_groups) as s
      left join aws_vpc_security_group as sg on sg.group_id = s ->> 'VpcSecurityGroupId'

    -- Kms key Nodes
    union all
    select
      null as from_id,
      null as to_id,
      k.arn as id,
      k.title as title,
      'aws_kms_key' as category,
      jsonb_build_object(
        'ARN', k.arn,
        'Account ID', k.account_id,
        'Region', k.region,
        'Key Manager', k.key_manager,
        'Enabled', enabled::text
      ) as properties
    from
      cluster as c
      left join aws_kms_key as k on k.arn = c.kms_key_id

    -- Kms key Edges
    union all
    select
      c.arn as from_id,
      k.arn as to_id,
      null as id,
      'Encrypted With' as title,
      'encrypted_with' as category,
      jsonb_build_object(
        'ARN', k.arn,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      cluster as c
      left join aws_kms_key as k on k.arn = c.kms_key_id

    -- IAM Role Nodes
    union all
    select
      null as from_id,
      null as to_id,
      r.arn as id,
      r.title as title,
      'aws_iam_role' as category,
      jsonb_build_object(
        'ARN', r.arn,
        'Role Id', r.role_id,
        'Account ID', r.account_id,
        'Description', r.description
      ) as properties
    from
      cluster as c,
      jsonb_array_elements(iam_roles) as ir
      left join aws_iam_role as r on r.arn = ir ->> 'IamRoleArn'
    
    -- IAM Role Edges
    union all
    select
      c.arn as from_id,
      r.arn as to_id,
      null as id,
      'Attached To' as title,
      'attached_to' as category,
      jsonb_build_object(
        'ARN', r.arn,
        'Role Id', r.role_id,
        'Account ID', r.account_id
      ) as properties
    from
      cluster as c,
      jsonb_array_elements(iam_roles) as ir
      left join aws_iam_role as r on r.arn = ir ->> 'IamRoleArn'

    -- Elastic IP Nodes
    union all
    select
      null as from_id,
      null as to_id,
      e.arn as id,
      e.title as title,
      'aws_vpc_eip' as category,
      jsonb_build_object(
        'ARN', e.arn,
        'Account ID', e.account_id,
        'Region', e.region,
        'Elastic IP', c.elastic_ip_status ->> 'ElasticIp',
        'Private IP', e.private_ip_address
      ) as properties
    from
      cluster as c
      left join aws_vpc_eip as e on e.public_ip = (c.elastic_ip_status ->> 'ElasticIp')::inet
    where
      c.elastic_ip_status is not null

    -- Elastic IP Edges
    union all
    select
      c.arn as from_id,
      e.arn as to_id,
      null as id,
      'Uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', e.arn,
        'Account ID', e.account_id,
        'Region', e.region
      ) as properties
    from
      cluster as c
      left join aws_vpc_eip as e on e.public_ip = (c.elastic_ip_status ->> 'ElasticIp')::inet
    where
      c.elastic_ip_status is not null

    -- CloudWatch Nodes
    union all
    select
      null as from_id,
      null as to_id,
      g.arn as id,
      g.title as title,
      'aws_cloudwatch_log_group' as category,
      jsonb_build_object(
        'ARN', g.arn,
        'Account ID', g.account_id,
        'Region', g.region,
        'Retention days', g.retention_in_days
      ) as properties
    from
      cluster as c
      left join aws_cloudwatch_log_group as g on g.title like '%' || c.title || '%'

    -- CloudWatch Edges
    union all
    select
      c.arn as from_id,
      g.arn as to_id,
      null as id,
      'Logs to' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', g.arn,
        'Account ID', g.account_id,
        'Region', g.region
      ) as properties
    from
      cluster as c
      left join aws_cloudwatch_log_group as g on g.title like '%' || c.title || '%'

    -- S3 Buckets - nodes
    union all
    select
      null as from_id,
      null as to_id,
      bucket.arn as id,
      bucket.name as title,
      'aws_s3_bucket' as category,
      jsonb_build_object(
        'ARN', bucket.arn,
        'Account ID', bucket.account_id,
        'Region', bucket.region,
        'Public', bucket_policy_is_public::text
      ) as properties
    from
      cluster as c
      left join aws_s3_bucket as bucket on bucket.name = c.logging_status ->> 'BucketName'

    -- S3 Buckets - edges
    union all
    select
      c.arn as from_id,
      bucket.arn as to_id,
      null as id,
      'Logs to' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', bucket.arn,
        'Account ID', bucket.account_id,
        'Region', bucket.region
      ) as properties
    from
      cluster as c
      left join aws_s3_bucket as bucket on bucket.name = c.logging_status ->> 'BucketName'

    -- Parameter Group Nodes
    union all
    select
      null as from_id,
      null as to_id,
      g.title as id,
      g.title as title,
      'aws_redshift_parameter_group' as category,
      jsonb_build_object(
        'ARN', g.title,
        'Account ID', g.account_id,
        'Region', g.region,
        'Description', g.description
      ) as properties
    from
      cluster as c,
      jsonb_array_elements(cluster_parameter_groups) as p
      left join aws_redshift_parameter_group as g on g.name = p ->> 'ParameterGroupName'

    -- Parameter Group Edges
    union all
    select
      c.arn as from_id,
      g.title as to_id,
      null as id,
      'Uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', g.title,
        'Account ID', g.account_id,
        'Region', g.region
      ) as properties
    from
      cluster as c,
      jsonb_array_elements(cluster_parameter_groups) as p
      left join aws_redshift_parameter_group as g on g.name = p ->> 'ParameterGroupName'
  EOQ

  param "bucket" {}
}
