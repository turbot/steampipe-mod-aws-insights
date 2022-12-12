dashboard "ec2_ami_detail" {

  title         = "AWS EC2 AMI Detail"
  documentation = file("./dashboards/ec2/docs/ec2_ami_detail.md")

  tags = merge(local.ec2_common_tags, {
    type = "Detail"
  })

  input "ami" {
    title = "Select an image:"
    query = query.ec2_ami_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.ec2_ami_state
      args = {
        image_id = self.input.ami.value
      }
    }

    card {
      width = 2
      query = query.ec2_ami_architecture
      args = {
        image_id = self.input.ami.value
      }
    }

    card {
      width = 2
      query = query.ec2_ami_hypervisor
      args = {
        image_id = self.input.ami.value
      }
    }

    card {
      width = 2
      query = query.ec2_ami_virtualization
      args = {
        image_id = self.input.ami.value
      }
    }

  }

  # container {

  #   graph {
  #     title     = "Relationships"
  #     type      = "graph"
  #     direction = "TD"

  #     with "ebs_snapshots" {
  #       sql = <<-EOQ
  #         select
  #           s.arn as ebs_snapshot_arn
  #         from
  #           aws_ebs_snapshot as s,
  #           aws_ec2_ami as ami,
  #           jsonb_array_elements(ami.block_device_mappings) as device_mappings
  #         where
  #           device_mappings -> 'Ebs' is not null
  #           and s.snapshot_id = device_mappings -> 'Ebs' ->> 'SnapshotId'
  #           and ami.image_id = $1
  #       EOQ

  #       args = [self.input.ami.value]
  #     }

  #     with "ec2_instances" {
  #       sql = <<-EOQ
  #         select
  #           arn as ec2_instance_arn
  #         from
  #           aws_ec2_instance
  #         where
  #           image_id = $1;
  #       EOQ

  #       args = [self.input.ami.value]
  #     }

  #     nodes = [
  #       node.ebs_snapshot,
  #       node.ec2_ami,
  #       node.ec2_instance
  #     ]

  #     edges = [
  #       edge.ebs_snapshot_to_ec2_ami,
  #       edge.ec2_ami_to_ec2_instance_edge
  #     ]

  #     args = {
  #       ec2_ami_image_ids = [self.input.ami.value]
  #       ebs_snapshot_arns = with.ebs_snapshots.rows[*].ebs_snapshot_arn
  #       ec2_instance_arns = with.ec2_instances.rows[*].ec2_instance_arn
  #     }
  #   }
  # }

  container {

    container {
      width = 6
      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.ec2_ami_overview
        args = {
          image_id = self.input.ami.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.ec2_ami_tags
        args = {
          image_id = self.input.ami.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "Sharing"
        query = query.ec2_ami_shared_with
        args = {
          image_id = self.input.ami.value
        }
      }

      table {
        title = "Instances"
        query = query.ec2_ami_instances
        args = {
          image_id = self.input.ami.value
        }
        column "link" {
          display = "none"
        }
        column "ID" {
          href = "{{ .link }}"
        }
      }
    }

  }

}

query "ec2_ami_input" {
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

query "ec2_ami_instances" {
  sql = <<-EOQ
    select
      instance_id as "ID",
      tags ->> 'Name' as "Name",
      instance_state as "Instance State",
      '${dashboard.ec2_instance_detail.url_path}?input.instance_arn=' || arn as link
    from
      aws_ec2_instance
    where
      image_id = $1;
  EOQ

  param "image_id" {}

}

query "ec2_ami_shared_with" {
  sql = <<-EOQ
    with sharing as (
      select
        lp
      from
        aws_ec2_ami as ami,
        jsonb_array_elements(ami.launch_permissions) as lp
      where image_id = $1
    )

    -- Accounts
    select
      lp ->> 'UserId' as "Shared With"
    from
      sharing
    where
      lp ->> 'UserId' is not null

    -- Organization
    union all
    select
      lp ->> 'OrganizationArn' as "Shared With"
    from
      sharing
    where
      lp ->> 'OrganizationArn' is not null

    -- Organizational Unit
    union all
    select
      lp ->> 'OrganizationalUnitArn' as "Shared With"
    from
      sharing
    where
      lp ->> 'OrganizationalUnitArn' is not null
  EOQ

  param "image_id" {}

}

query "ec2_ami_state" {
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

query "ec2_ami_architecture" {
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

query "ec2_ami_hypervisor" {
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

query "ec2_ami_virtualization" {
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

query "ec2_ami_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      image_id as "Image ID",
      image_type as "Image Type",
      image_location as "Image Location",
      root_device_type as "Root Device Type",
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

query "ec2_ami_tags" {
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
