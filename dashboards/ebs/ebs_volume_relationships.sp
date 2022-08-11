dashboard "aws_ebs_volume_relationships" {

  title         = "AWS EBS Volume Relationships"
  # documentation = file("./dashboards/ebs/docs/ebs_volume_relationships.md")

  tags = merge(local.ebs_common_tags, {
    type = "Relationships"
  })

  input "volume_arn" {
    title = "Select a volume:"
    sql   = query.aws_ebs_volume_input.sql
    width = 4
  }
  
  graph {
    type  = "graph"
    title = "Things I use..."
    query = query.aws_ebs_volume_graph_i_use
    args  = {
      arn = self.input.volume_arn.value
    }

    category "aws_kms_key" {
      href = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.'ARN' | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/kms_key_light.svg"))
    }

    category "aws_ebs_volume" {
      href = "${dashboard.aws_ebs_volume_detail.url_path}?input.volume_arn={{.properties.'ARN' | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/ebs_volume_light.svg"))
    }
    
    category "aws_ec2_instance" {
      href = "${dashboard.aws_ec2_instance_detail.url_path}?input.instance_arn={{.properties.'ARN' | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/ec2_instance_light.svg"))
    }

    category "aws_ebs_snapshot" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/ebs_snapshot_light.svg"))
    }

  }
  
  graph {
    type  = "graph"
    title = "Things that use me..."
    query = query.aws_ebs_volume_graph_use_me
    args  = {
      arn = self.input.volume_arn.value
    }

    category "aws_ebs_volume" {
      href = "${dashboard.aws_ebs_volume_detail.url_path}?input.volume_arn={{.properties.'ARN' | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/ebs_volume_light.svg"))
    }
    
    category "aws_ec2_instance" {
      href = "${dashboard.aws_ec2_instance_detail.url_path}?input.instance_arn={{.properties.'ARN' | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/ec2_instance_light.svg"))
    }
  }
  
}

query "aws_ebs_volume_graph_i_use" {
  sql = <<-EOQ
    with volumes as (select arn,volume_id,title,account_id,region,size,kms_key_id from aws_ebs_volume where arn = $1)
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_ebs_volume' as category,
      jsonb_build_object(
        'ID',volumes.volume_id,
        'ARN',volumes.arn,
        'Size',volumes.size,
        'Account ID', volumes.account_id,
        'Region', volumes.region,
        'KMS Key ID', volumes.kms_key_id
      ) as properties
    from
      volumes

    -- kms - nodes
    union all
    select
      null as from_id,
      null as to_id,
      kms_keys.arn as id,
      kms_keys.title as title,
      'aws_kms_key' as category,
      jsonb_build_object(
        'ARN', kms_keys.arn,
        'Account ID',kms_keys.account_id,
        'Region', kms_keys.region,
        'Key Manager', kms_keys.key_manager
      ) as properties
    from
      aws_kms_key as kms_keys,
      volumes
    where
      volumes.kms_key_id = kms_keys.arn

    -- kms - edges
    union all
    select
      volumes.arn as to_id,
      kms_keys.arn as from_id,
      null as id,
      'uses' as title,
      'aws_ec2_instance' as category,
      jsonb_build_object(
        'ARN', kms_keys.arn,
        'Account ID',kms_keys.account_id,
        'Region', kms_keys.region,
        'Key Manager', kms_keys.key_manager
      ) as properties
    from
      aws_kms_key as kms_keys,
      volumes
    where
      volumes.kms_key_id = kms_keys.arn

    -- snapshots - nodes
    union all
    select
      null as from_id,
      null as to_id,
      snapshot.arn as id,
      snapshot.title as title,
      'aws_ebs_snapshot' as category,
      jsonb_build_object(
        'ARN', snapshot.arn,
        'Account ID',snapshot.account_id,
        'Region', snapshot.region,
        'Snapshot Size', snapshot.volume_size
      ) as properties
    from
      aws_ebs_snapshot as snapshot,
      volumes
    where
      volumes.volume_id = snapshot.volume_id

    -- snapshots - nodes
    union all
    select
      volumes.arn as from_id,
      snapshot.arn as to_id,
      snapshot.arn as id,
      snapshot.title as title,
      'aws_ebs_snapshot' as category,
      jsonb_build_object(
        'ARN', snapshot.arn,
        'Account ID',snapshot.account_id,
        'Region', snapshot.region,
        'Snapshot Size', snapshot.volume_size
      ) as properties
    from
      aws_ebs_snapshot as snapshot,
      volumes
    where
      volumes.volume_id = snapshot.volume_id

  EOQ
  
  param "arn" {}
}



query "aws_ebs_volume_graph_use_me" {
  sql = <<-EOQ
    with volumes as (select arn,volume_id,title,account_id,region,size from aws_ebs_volume where arn = $1)
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_ebs_volume' as category,
      jsonb_build_object(
        'ID',volumes.volume_id,
        'ARN',volumes.arn,
        'Size',volumes.size,
        'Account ID', volumes.account_id,
        'Region', volumes.region
      ) as properties
    from
      volumes

    -- instances - nodes
    union all
    select
      null as from_id,
      null as to_id,
      instances.arn as id,
      instance_id as title,
      'aws_ec2_instance' as category,
      jsonb_build_object(
        'Name', instances.tags ->> 'Name',
        'Instance ID', instance_id,
        'ARN', instances.arn,
        'Account ID',instances.account_id,
        'Region', instances.region
      ) as properties
    from
      aws_ec2_instance as instances,
      jsonb_array_elements(instances.block_device_mappings) as bdm,
      volumes
    where
      bdm -> 'Ebs' ->> 'VolumeId' in (select volume_id from volumes) 

    -- instances - edges
    union all
    select
      instances.arn as from_id,
      volumes.arn as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Name', instances.tags ->> 'Name',
        'Instance ID', instance_id,
        'ARN', instances.arn,
        'Account ID',instances.account_id,
        'Region', instances.region
      ) as properties
    from
      aws_ec2_instance as instances,
      jsonb_array_elements(instances.block_device_mappings) as bdm,
      volumes
    where
      bdm -> 'Ebs' ->> 'VolumeId' in (select volume_id from volumes) 



  EOQ
  
  param "arn" {}
}
