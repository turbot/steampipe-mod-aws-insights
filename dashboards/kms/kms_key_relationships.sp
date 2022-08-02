dashboard "aws_kms_key_relationships" {
  title         = "AWS KMS Key Relationships"
  #documentation = file("./dashboards/kms/docs/kms_key_relationships.md")
  tags = merge(local.kms_common_tags, {
    type = "Relationships"
  })
  
  input "key_arn" {
    title = "Select a key:"
    query = query.aws_kms_key_input
    width = 4
  }
  
  graph {
    type  = "graph"
    title = "Things I use..."
    query = query.aws_kms_key_graph_from_key
    args = {
      arn = self.input.key_arn.value
    }
    category "aws_kms_key" {
      color = "orange"
      href  = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.ARN | @uri}}"
    }
  
    category "uses" {
      color = "green"
    }
  }
  
  graph {
    type  = "graph"
    title = "Things that use me..."
    query = query.aws_kms_key_graph_to_key
    args = {
      arn = self.input.key_arn.value
    }
    category "aws_kms_key" {
      color = "orange"
      href  = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.ARN | @uri}}"
    }

    category "aws_ec2_instance" {
      color = "blue"
      href  = "${dashboard.aws_ec2_instance_detail.url_path}?input.instance_id={{.properties.'Instance ID' | @uri}}"
    }

    category "uses" {
      color = "green"
    }
  }
}

query "aws_kms_key_graph_from_key" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      id as id,
      id as title,
      'aws_kms_key' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id
      ) as properties
    from
      aws_kms_key
    where
      arn = $1
  EOQ
  
  param "arn" {}
}

query "aws_kms_key_graph_to_key" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      id as id,
      id as title,
      'aws_kms_key' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id
      ) as properties
    from
      aws_kms_key
    where
      arn = $1
    
    -- Cloud Trail - nodes
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      name as title,
      'aws_cloudtrail_trail' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Home Region', home_region
      ) as properties
    from
      aws_cloudtrail_trail as t,
      aws_kms_key as k
    where
      t.kms_key_id = k.id and k.arn = $1  

    -- EBS Volume - nodes
    union all
    select
      null as from_id,
      null as to_id,
      volume_id as id,
      volume_id as title,
      'aws_ebs_volume' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ebs_volume as v,
      aws_kms_key as k
    where
      v.kms_key_id = k.id and k.arn = $1 

    -- RDS DB Cluster Snapshot - nodes
    union all
    select
      null as from_id,
      null as to_id,
      db_cluster_snapshot_identifier as id,
      db_cluster_snapshot_identifier as title,
      'aws_rds_db_cluster_snapshot' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_rds_db_cluster_snapshot as s,
      aws_kms_key as k
    where
      s.kms_key_id = k.id and k.arn = $1   

    -- RDS DB Cluster - nodes
    union all
    select
      null as from_id,
      null as to_id,
      db_cluster_identifier as id,
      db_cluster_identifier as title,
      'aws_rds_db_cluster' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_rds_db_cluster as c,
      aws_kms_key as k
    where
      c.kms_key_id = k.id and k.arn = $1  

    -- RDS DB Instance - nodes
    union all
    select
      null as from_id,
      null as to_id,
      db_instance_identifier as id,
      db_instance_identifier as title,
      'aws_rds_db_instance' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_rds_db_instance as i,
      aws_kms_key as k
    where
      i.kms_key_id = k.id and k.arn = $1 

    -- RDS DB Instance Snapshot - nodes
    union all
    select
      null as from_id,
      null as to_id,
      db_snapshot_identifier as id,
      db_snapshot_identifier as title,
      'aws_rds_db_snapshot' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_rds_db_snapshot as s,
      aws_kms_key as k
    where
      s.kms_key_id = k.id and k.arn = $1  

    -- Redshift Cluster - nodes
    union all
    select
      null as from_id,
      null as to_id,
      cluster_identifier as id,
      cluster_identifier as title,
      'aws_redshift_cluster' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_redshift_cluster as c,
      aws_kms_key as k
    where
      c.kms_key_id = k.id and k.arn = $1  

     -- Redshift Cluster - nodes
    union all
    select
      null as from_id,
      null as to_id,
      cluster_identifier as id,
      cluster_identifier as title,
      'aws_redshift_cluster' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_redshift_cluster as c,
      aws_kms_key as k
    where
      c.kms_key_id = k.id and k.arn = $1    


     -- Instance Profile  - Edges
    union all
    select
      key_id as from_id,
      kms_instance_profile_arn as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Instance Profile ARN', kms_instance_profile_arn
      ) as properties
    from
      aws_kms_key,
      jsonb_array_elements_text(instance_profile_arns) as kms_instance_profile_arn
    where 
      arn = $1 
    
    -- Instance for Instance Profile - nodes
    union all
    select
      null as from_id,
      null as to_id,
      i.instance_id as id,
      i.instance_id as title,
      'aws_ec2_instance' as category,
      jsonb_build_object(
        'Name', i.tags ->> 'Name',
        'Instance ID', instance_id,
        'ARN', i.arn,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_ec2_instance as i,
      aws_kms_key as r,
      jsonb_array_elements_text(instance_profile_arns) as instance_profile
    where
      r.arn = $1 and instance_profile = i.kms_instance_profile_arn
    
    -- Instance for Instance Profile  - Edges
    union all
    select
      i.kms_instance_profile_arn as from_id,
      i.instance_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Instance ARN', i.arn,
        'Instance Profile ARN', i.kms_instance_profile_arn,
        'Account ID', i.account_id
      ) as properties
    from
      aws_ec2_instance as i,
      aws_kms_key as r,
      jsonb_array_elements_text(instance_profile_arns) as instance_profile
    where
      r.arn = $1 and instance_profile = i.kms_instance_profile_arn  
    order by 
      category,from_id,to_id
  EOQ
  
  param "arn" {}
}