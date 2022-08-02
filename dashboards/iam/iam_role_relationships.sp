dashboard "aws_iam_role_relationships" {
  title         = "AWS IAM Role Relationships"
  #documentation = file("./dashboards/iam/docs/iam_role_relationships.md")
  tags = merge(local.iam_common_tags, {
    type = "Relationships"
  })
  
  input "role_arn" {
    title = "Select a role:"
    query = query.aws_iam_role_input
    width = 4
  }
  
  graph {
    type  = "graph"
    title = "Things I use..."
    query = query.aws_iam_role_graph_from_role
    args = {
      arn = self.input.role_arn.value
    }
    category "aws_iam_role" {
      color = "orange"
      href  = "${dashboard.aws_iam_role_detail.url_path}?input.role_arn={{.properties.ARN | @uri}}"

      icon = {}
      
      properties {
        property "Name" {
          
        }

        property "Account ID" {
          
        } 

        property  "ARN" {
          display = "none"
        }

        order = [
          'Name', 
          'ARN',
          'Account ID'
        ]
      }
    }
    
    category "aws_iam_user" {
      color = "yellow"
      href  = "${dashboard.aws_iam_user_detail.url_path}?input.user_arn={{.properties.ARN | @uri}}"
    }

    category "aws_iam_group" {
      color = "yellow"
      href  = "${dashboard.aws_iam_group_detail.url_path}?input.group_arn={{.properties.ARN | @uri}}"
    }

    category "aws_iam_policy" {
      color = "blue"
    }

    category "uses" {
      color = "green"
    }
  }
  
  graph {
    type  = "graph"
    title = "Things that use me..."
    query = query.aws_iam_role_graph_to_role
    args = {
      arn = self.input.role_arn.value
    }
    category "aws_iam_role" {
      color = "orange"
      href  = "${dashboard.aws_iam_role_detail.url_path}?input.role_arn={{.properties.ARN | @uri}}"
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

query "aws_iam_role_graph_from_role" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      role_id as id,
      name as title,
      'aws_iam_role' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id
      ) as properties
    from
      aws_iam_role
    where
      arn = $1

    -- Attached Policies - nodes
    union all
    select
      null as from_id,
      null as to_id,
      policy_id as id,
      name as title,
      'aws_iam_policy' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id
      ) as properties
    from
      aws_iam_policy
    where
      arn in (select jsonb_array_elements_text(attached_policy_arns) from aws_iam_role where arn = $1)

    -- Attached Policies - Edges
    union all
    select
      r.role_id as from_id,
      p.policy_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Policy Name', p.name,
        'AWS Managed', p.is_aws_managed     
      ) as properties
    from
      aws_iam_role as r,
      jsonb_array_elements_text(attached_policy_arns) as arns 
      left join aws_iam_policy as p on p.arn = arns 
    where 
      r.arn = $1   

    -- User - nodes
    union all
    select
      null as from_id,
      null as to_id,
      u.name as id,
      u.name as title,
      'aws_iam_user' as category,
      jsonb_build_object(
        'ARN', u.arn,
        'Account ID', u.account_id
      ) as properties
    from
      aws_iam_user as u,
      jsonb_array_elements_text(attached_policy_arns) as arns,
      aws_iam_policy as p
    where
      p.arn = arns and p.arn in (select jsonb_array_elements_text(attached_policy_arns) from aws_iam_role where arn = $1)
    
    -- User - Edges
    union all
    select
      p.policy_id as from_id,
      u.name as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', u.arn,
        'Account ID', u.account_id
      ) as properties
    from
      aws_iam_user as u,
      jsonb_array_elements_text(attached_policy_arns) as arns,
      aws_iam_policy as p
    where
      p.arn = arns and p.arn in (select jsonb_array_elements_text(attached_policy_arns) from aws_iam_role where arn = $1)
    
    -- Group - nodes
    union all
    select
      null as from_id,
      null as to_id,
      g.name as id,
      g.name as title,
      'aws_iam_group' as category,
      jsonb_build_object(
        'ARN', g.arn,
        'Account ID', g.account_id
      ) as properties
    from
      aws_iam_group as g,
      jsonb_array_elements_text(attached_policy_arns) as arns,
      aws_iam_policy as p
    where
      p.arn = arns and p.arn in (select jsonb_array_elements_text(attached_policy_arns) from aws_iam_role where arn = $1)

    -- Group - Edges
    union all
    select
      p.policy_id as from_id,
      g.name as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', g.arn,
        'Account ID', g.account_id
      ) as properties
    from
      aws_iam_group as g,
      jsonb_array_elements_text(attached_policy_arns) as arns,
      aws_iam_policy as p
    where
      p.arn = arns and p.arn in (select jsonb_array_elements_text(attached_policy_arns) from aws_iam_role where arn = $1)

    order by
      category,from_id,to_id;   
  EOQ
  
  param "arn" {}
}

query "aws_iam_role_graph_to_role" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      role_id as id,
      name as title,
      'aws_iam_role' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id
      ) as properties
    from
      aws_iam_role
    where
      arn = $1
    
    -- Instance Profile - nodes
    union all
    select
      null as from_id,
      null as to_id,
      iam_instance_profile_arn as id,
      iam_instance_profile_arn as title,
      'iam_instance_profile_arn' as category,
      jsonb_build_object(
        'Instance Profile ARN', iam_instance_profile_arn
      ) as properties
    from
      aws_iam_role,
      jsonb_array_elements_text(instance_profile_arns) as iam_instance_profile_arn
    where
      arn = $1  

     -- Instance Profile  - Edges
    union all
    select
      role_id as from_id,
      iam_instance_profile_arn as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Instance Profile ARN', iam_instance_profile_arn
      ) as properties
    from
      aws_iam_role,
      jsonb_array_elements_text(instance_profile_arns) as iam_instance_profile_arn
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
      aws_iam_role as r,
      jsonb_array_elements_text(instance_profile_arns) as instance_profile
    where
      r.arn = $1 and instance_profile = i.iam_instance_profile_arn
    
    -- Instance for Instance Profile  - Edges
    union all
    select
      i.iam_instance_profile_arn as from_id,
      i.instance_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Instance ARN', i.arn,
        'Instance Profile ARN', i.iam_instance_profile_arn,
        'Account ID', i.account_id
      ) as properties
    from
      aws_ec2_instance as i,
      aws_iam_role as r,
      jsonb_array_elements_text(instance_profile_arns) as instance_profile
    where
      r.arn = $1 and instance_profile = i.iam_instance_profile_arn  
    order by 
      category,from_id,to_id
  EOQ
  
  param "arn" {}
}