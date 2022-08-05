
dashboard "aws_ec2_instance_relationships" {
  title         = "AWS EC2 Instance Relationships"
  #documentation = file("./dashboards/ec2/docs/ec2_instance_relationships.md")
  tags = merge(local.ec2_common_tags, {
    type = "Relationships"
  })
  
  input "instance_arn" {
    title = "Select an instance:"
    sql   = query.aws_ec2_instance_input.sql
    width = 4
  }
  
  graph {
    type  = "graph"
    title = "Things I use..."
    query = query.aws_ec2_instance_graph_from_instance
    args = {
      arn = self.input.instance_arn.value
    }
    
    category "aws_ec2_instance" {
      href = "${dashboard.aws_ec2_instance_detail.url_path}?input.instance_arn={{.properties.'ARN' | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/ebs_volume.svg"))
    }

    category "aws_ebs_volume" {
      href = "${dashboard.aws_ebs_volume_detail.url_path}?input.volume_arn={{.properties.'ARN' | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/ec2.svg"))
    }
    
    category "aws_ec2_network_interface" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/eni.svg"))
    }
    
    category "aws_ec2_ami" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/ami.svg"))
    }
    
  }
  
  graph {
    type  = "graph"
    title = "Things that use me..."
    query = query.aws_ec2_instance_graph_to_instance
    args = {
      arn = self.input.instance_arn.value
    }
    
    category "aws_ec2_instance" {
      href = "${dashboard.aws_ec2_instance_detail.url_path}?input.instance_arn={{.properties.'ARN' | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/ebs_volume.svg"))
    }

    category "aws_ebs_volume" {
      href = "${dashboard.aws_ebs_volume_detail.url_path}?input.volume_arn={{.properties.'ARN' | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/ec2.svg"))
    }

    category "aws_ec2_network_interface" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/eni.svg"))
    }
    
    category "aws_ec2_ami" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/ami.svg"))
    }
    
  }
}

query "aws_ec2_instance_graph_from_instance" {
  sql = <<-EOQ
    with instances as (select arn,instance_id,tags,account_id,region,block_device_mappings,security_groups,subnet_id,iam_instance_profile_arn,iam_instance_profile_id,image_id,key_name from aws_ec2_instance where arn = $1)
    select
      null as from_id,
      null as to_id,
      instance_id as id,
      instance_id as title,
      'aws_ec2_instance' as category,
      jsonb_build_object(
        'Name', tags ->> 'Name',
        'Instance ID', instance_id,
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      instances

    -- EBS Volumes - nodes
    union all
    select
      null as from_id,
      null as to_id,
      bd -> 'Ebs' ->> 'VolumeId' as id,
      bd -> 'Ebs' ->> 'VolumeId' as title,
      'aws_ebs_volume' as category,
      jsonb_build_object(
        'Volume ID', bd -> 'Ebs' ->> 'VolumeId',
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      instances,
      jsonb_array_elements(block_device_mappings) as bd

    -- EBS Volumes - Edges
    union all
    select
      instance_id as from_id,
      bd -> 'Ebs' ->> 'VolumeId' as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Volume ID', bd -> 'Ebs' ->> 'VolumeId',
        'Device Name', bd ->> 'DeviceName',
        'Status', bd -> 'Ebs' ->> 'Status',
        'Attach Time', bd -> 'Ebs' ->> 'AttachTime',
        'Delete On Termination', bd -> 'Ebs' ->> 'DeleteOnTermination'        
      ) as properties
    from
      instances,
      jsonb_array_elements(block_device_mappings) as bd

    -- ENIs - nodes
    union all
    select
      null as from_id,
      null as to_id,
      eni.network_interface_id as id,
      eni.network_interface_id as title,
      'aws_ec2_network_interface' as category,
       jsonb_build_object(
        'Name', eni.tags ->> 'Name',
        'Description', eni.description,
        'Interface ID', eni.network_interface_id,
        'Public IP', eni.association_public_ip,
        'Private IP', eni.private_ip_address,
        'Public DNS Name', eni.association_public_dns_name,
        'Private DNS Name', eni.private_dns_name,
        'MAC Address', eni.mac_address,
        'Account ID', eni.account_id,
        'Region', eni.region
      ) as properties
    from
      instances as i,
      aws_ec2_network_interface as eni
    where 
      eni.attached_instance_id = i.instance_id

    -- ENIs - Edges
    union all
    select
      instance_id as from_id,
      eni.network_interface_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Status', status,
        'Attachment ID', attachment_id,
        'Attachment Status', attachment_status,
        'Attachment Time', attachment_time,
        'Delete on Instance Termination', delete_on_instance_termination,
        'Device Index', device_index
      ) as properties
    from
      instances as i,
      aws_ec2_network_interface as eni
    where 
      eni.attached_instance_id = i.instance_id

    -- Security Groups - nodes
    union all
    select
      null as from_id,
      null as to_id,
      sg ->> 'GroupId' as id,
      sg ->> 'GroupId' as title,
      'aws_vpc_security_group' as category,
      jsonb_build_object(
        'ID', sg ->> 'GroupId',
        'Name', sg ->> 'GroupName',
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      instances,
      jsonb_array_elements(security_groups) as sg

    -- Security Groups- Edges
    union all
    select
      instance_id as from_id,
      sg ->> 'GroupId' as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ID', sg ->> 'GroupId',
        'Name', sg ->> 'GroupName',
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      instances,
      jsonb_array_elements(security_groups) as sg

   
    -- Subnet - nodes
    union all
    select
      null as from_id,
      null as to_id,
      subnet.subnet_id as id,
      subnet.subnet_id as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'Name', subnet.tags ->> 'Name',
        'Subnet ID', subnet.subnet_id ,
        'CIDR Block', subnet.cidr_block,
        'AZ', subnet.availability_zone,
        'Account ID', subnet.account_id,
        'Region', subnet.region
      ) as properties
    from
      instances as i,
      aws_vpc_subnet as subnet
    where 
      i.subnet_id = subnet.subnet_id

   -- Subnet - edges
    union all
    select
      i.instance_id as from_id,
      subnet.subnet_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Name', subnet.tags ->> 'Name',
        'Subnet ID', subnet.subnet_id,
        'State', subnet.state 
      ) as properties
    from
      instances as i,
      aws_vpc_subnet as subnet
    where 
      i.subnet_id = subnet.subnet_id


    -- Instance Profile - nodes
    union all
    select
      null as from_id,
      null as to_id,
      iam_instance_profile_arn as id,
      iam_instance_profile_arn as title,
      'iam_instance_profile_arn' as category,
      jsonb_build_object(
        'Instance Profile ARN', iam_instance_profile_arn,
        'Instance Profile ID', iam_instance_profile_id
      ) as properties
    from
      instances

    -- Instance Profile  - Edges
    union all
    select
      instance_id as from_id,
      iam_instance_profile_arn as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Instance Profile ARN', iam_instance_profile_arn,
        'Instance Profile ID', iam_instance_profile_id
      ) as properties
    from
      instances


    -- Role for Instance Profile - nodes
    union all
    select
      null as from_id,
      null as to_id,
      r.arn as id,
      r.name as title,
      'aws_iam_role' as category,
      jsonb_build_object(
        'Name', r.name,
        'Description', r.description,
        'ARN', r.arn ,
        'Account ID', r.account_id
      ) as properties
    from
      instances as i,
      aws_iam_role as r,
      jsonb_array_elements_text(instance_profile_arns) as instance_profile
    where
      instance_profile = i.iam_instance_profile_arn

    -- Role for Instance Profile  - Edges
    union all
    select
      i.iam_instance_profile_arn as from_id,
      r.arn as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Role ARN', r.arn,
        'Instance Profile ARN', i.iam_instance_profile_arn,
        'Account ID', r.account_id
      ) as properties
    from
      instances as i,
      aws_iam_role as r,
      jsonb_array_elements_text(instance_profile_arns) as instance_profile
    where
      instance_profile = i.iam_instance_profile_arn

    -- AMI- nodes
    union all
    select
      null as from_id,
      null as to_id,
      image_id as id,
      image_id as title,
      'aws_ec2_ami' as category,
      jsonb_build_object(
        'Image ID', image_id
      ) as properties
    from
      instances as i

   -- AMI- edges
    union all
    select
      instance_id as from_id,
      image_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Image ID', image_id,
        'Instance ID', instance_id
      ) as properties
    from
      instances as i
      

    -- Key Pairs - nodes
    union all
    select
      null as from_id,
      null as to_id,
      i.key_name as id,
      i.key_name as title,
      'aws_ec2_key_pair' as category,
      jsonb_build_object(
        'Name', k.key_name,
        'ID', k.key_pair_id,
        'Fingerprint', key_fingerprint
      ) as properties
    from
      instances as i,
      aws_ec2_key_pair as k
    where 
      i.key_name = k.key_name
      and i.account_id = k.account_id 
      and i.region = k.region

   -- Key Pairs  - edges
    union all
    select
      instance_id as from_id,
      key_name as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Name', key_name,
        'Instance ID', instance_id
      ) as properties
    from
      instances as i
      
    order by category,from_id,to_id
      
  EOQ
  
  param "arn" {}
}

query "aws_ec2_instance_graph_to_instance" {
  sql = <<-EOQ
    with instances as (select * from aws_ec2_instance where arn = $1)
    select
      null as from_id,
      null as to_id,
      instance_id as id,
      instance_id as title,
      'aws_ec2_instance' as category,
      jsonb_build_object(
        'Name', tags ->> 'Name',
        'Instance ID', instance_id,
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      instances

    -- AutoScaling Groups - nodes
    union all
    select
      null as from_id,
      null as to_id,
      k.autoscaling_group_arn as id,
      k.name as title,
      'aws_ec2_autoscaling_group' as category,
      jsonb_build_object('instance', group_instance->>'InstanceId','i', instances.instance_id, 'asg', group_instance) as properties
    from
      aws_ec2_autoscaling_group as k,
      jsonb_array_elements(k.instances) as group_instance,
      instances
    where 
      group_instance->>'InstanceId' = instances.instance_id
      

    -- AutoScaling Groups - edges
    union all
    select
      k.autoscaling_group_arn as from_id,
      instances.instance_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object() as properties
    from
      aws_ec2_autoscaling_group as k,
      jsonb_array_elements(k.instances) as group_instance,
      instances
    where 
      group_instance->>'InstanceId' = instances.instance_id

    -- Classic LB - nodes
    union all
    select
      null as from_id,
      null as to_id,
      k.arn as id,
      k.name as title,
      'aws_ec2_classic_load_balancer' as category,
      jsonb_build_object('instance', group_instance->>'InstanceId','i', instances.instance_id, 'clb', group_instance) as properties
    from
      aws_ec2_classic_load_balancer as k,
      jsonb_array_elements(k.instances) as group_instance,
      instances
    where 
      group_instance->>'InstanceId' = instances.instance_id

    -- Classic LB - edges
    union all
    select
      k.arn as from_id,
      instances.instance_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object('instance', group_instance->>'InstanceId','i', instances.instance_id, 'clb', group_instance) as properties
    from
      aws_ec2_classic_load_balancer as k,
      jsonb_array_elements(k.instances) as group_instance,
      instances
    where 
      group_instance->>'InstanceId' = instances.instance_id
      
    order by category,from_id,to_id
  EOQ
  
  param "arn" {}
}