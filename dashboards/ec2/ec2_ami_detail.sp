dashboard "aws_ec2_ami_detail" {

  title         = "AWS EC2 AMI Detail"
  documentation = file("./dashboards/ec2/docs/ec2_ami_detail.md")

  tags = merge(local.ec2_common_tags, {
    type = "Detail"
  })

  input "ami" {
    title = "Select an image:"
    sql   = query.aws_ec2_ami_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_ec2_ami_state
      args = {
        image_id = self.input.ami.value
      }
    }
    
    card {
      width = 2
      query = query.aws_ec2_ami_architecture
      args = {
        image_id = self.input.ami.value
      }
    }
    
    card {
      width = 2
      query = query.aws_ec2_ami_hypervisor
      args = {
        image_id = self.input.ami.value
      }
    }
    
    card {
      width = 2
      query = query.aws_ec2_ami_virtualization
      args = {
        image_id = self.input.ami.value
      }
    }

  }
  
  container {
    graph {
      type  = "graph"
      base  = graph.aws_graph_categories
      query = query.aws_ec2_ami_relationships_graph
      
      args = {
        image_id = self.input.ami.value
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
        query = query.aws_ec2_ami_overview
        args = {
          image_id = self.input.ami.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_ec2_ami_tags
        args = {
          image_id = self.input.ami.value
        }
      }
    }
    
    container {
      width = 6
      table {
        title = "Instances"
        width = 12
        query = query.aws_ec2_ami_instances
        args = {
          image_id = self.input.ami.value
        }
      }
    }
  }
  
  container {
    title = "AMI Sharing"
    
    table {
      title = "Shared with Accounts"
      width = 4
      query = query.aws_ec2_ami_shared_with_user
      args = {
        image_id = self.input.ami.value
      }
    }
    table {
      title = "Shared with Organizations"
      width = 4
      query = query.aws_ec2_ami_shared_with_org
      args = {
        image_id = self.input.ami.value
      }
    }
    table {
      title = "Shared with OUs"
      width = 4
      query = query.aws_ec2_ami_shared_with_ou
      args = {
        image_id = self.input.ami.value
      }
    }
  }
}

query "aws_ec2_ami_input" {
  sql = <<-EOQ
    select
      name as label,
      image_id as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_ec2_ami
    order by
      title;
  EOQ
}

query "aws_ec2_ami_instances" {
  sql = <<-EOQ
    select
      instance_id as "ID",
      instance_state as "Instance State"
    from
      aws_ec2_instance
    where
      image_id = $1;
  EOQ

  param "image_id" {}

}

query "aws_ec2_ami_shared_with_user" {
  sql = <<-EOQ
    select
      'List' as "Account ID"
  EOQ

  param "image_id" {}

}
query "aws_ec2_ami_shared_with_org" {
  sql = <<-EOQ
    select
      'List' as "Organization ARN"
  EOQ

  param "image_id" {}

}
query "aws_ec2_ami_shared_with_ou" {
  sql = <<-EOQ
    select
      'List' as "Organizational Unit ARN"
  EOQ

  param "image_id" {}

}

query "aws_ec2_ami_state" {
  sql = <<-EOQ
    select
      'State' as label,
      initcap(state) as value
    from
      aws_ec2_ami
    where
      image_id = $1;
  EOQ

  param "image_id" {}

}

query "aws_ec2_ami_architecture" {
  sql = <<-EOQ
    select
      'Architecture' as label,
      architecture as value
    from
      aws_ec2_ami
    where
      image_id = $1;
  EOQ

  param "image_id" {}

}

query "aws_ec2_ami_hypervisor" {
  sql = <<-EOQ
    select
      'Hypervisor' as label,
      hypervisor as value
    from
      aws_ec2_ami
    where
      image_id = $1;
  EOQ

  param "image_id" {}

}

query "aws_ec2_ami_virtualization" {
  sql = <<-EOQ
    select
      'Virtualization Type' as label,
      virtualization_type as value
    from
      aws_ec2_ami
    where
      image_id = $1;
  EOQ

  param "image_id" {}

}

query "aws_ec2_ami_overview" {
  sql = <<-EOQ
    select
      launch_permissions,
      name as "Name",
      description as "Description",
      image_id as "Image ID",
      image_type as "Image yype",
      image_location as "Image location",
      architecture as "Architecture",
      hypervisor as "Hypervisor",
      root_device_type as "Root device type",
      ena_support as "ENA Support",
      account_id as "Account ID",
      region as "Region"
    from
      aws_ec2_ami
    where
      image_id = $1;
  EOQ

  param "image_id" {}
}

query "aws_ec2_ami_tags" {
  sql = <<-EOQ
    select
      t ->> 'Key' as "Key",
      t ->> 'Value' as "Value"
    from
      aws_ec2_ami a,
      jsonb_array_elements(a.tags_src) as t
    where
      image_id = $1
    order by
      t ->> 'Key';
    EOQ

  param "image_id" {}
}

query "aws_ec2_ami_relationships_graph"{
  sql = <<-EOQ
    with ami as
    (
      select
        *
      from
        aws_ec2_ami
      where
        image_id = $1
    )

    -- Resource (node)
    select
      null as from_id,
      null as to_id,
      image_id as id,
      name as title,
      'aws_ec2_ami' as category,
      jsonb_build_object(
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      ami

    -- To EC2 Instance (node)
    union all
    select
      null as from_id,
      null as to_id,
      instances.instance_id as id,
      instances.tags->>'Name' as title,
      'aws_ec2_instance' as category,
      jsonb_build_object(
        'Name', instances.tags ->> 'Name',
        'Instance ID', instances.instance_id,
        'ARN', instances.arn,
        'Account ID', instances.account_id,
        'Region', instances.region
      ) as properties
    from
      aws_ec2_instance as instances,
      ami
    where
      instances.image_id = ami.image_id   
      
    -- To EC2 Instance (edge)
    union all
    select
      instances.instance_id as from_id,
      ami.image_id as to_id,
      null as id,
      'launched with' as title,
      'ec2_ami_to_ec2_instance' as category,
      jsonb_build_object(
        'Name', instances.tags ->> 'Name',
        'Instance ID', instances.instance_id,
        'ARN', instances.arn,
        'Account ID', instances.account_id,
        'Region', instances.region
      ) as properties
    from
      aws_ec2_instance as instances,
      ami
    where
      instances.image_id = ami.image_id

    -- From EBS snapshots (node)
    union all
    select
      null as from_id,
      null as to_id,
      device_mappings -> 'Ebs' ->> 'SnapshotId' as id,
      snapshot.title as title,
      'aws_ebs_snapshot' as category,
      jsonb_build_object(
        'ARN', snapshot.arn,
        'SnapshotId', device_mappings -> 'Ebs' ->> 'SnapshotId',
        'Account ID', snapshot.account_id,
        'Region', snapshot.region
      ) as properties
    from
      aws_ebs_snapshot as snapshot,
      ami,
      jsonb_array_elements(ami.block_device_mappings) as device_mappings
    where
      device_mappings -> 'Ebs' is not null
      and snapshot.snapshot_id = device_mappings -> 'Ebs' ->> 'SnapshotId'

    -- From EBS snapshots (node)
    union all
    select
      ami.image_id as from_id,
      device_mappings -> 'Ebs' ->> 'SnapshotId' as to_id,
      null as id,
      'created from' as title,
      'ec2_ami_to_ebs_snapshot' as category,
      jsonb_build_object(
        'SnapshotId', device_mappings -> 'Ebs' ->> 'SnapshotId'
      ) as properties
    from
      ami,
      jsonb_array_elements(ami.block_device_mappings) as device_mappings
    where
      device_mappings -> 'Ebs' is not null
    
    order by
      category,
      from_id,
      to_id;
  EOQ

  param "image_id" {}
}