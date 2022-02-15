variable "iam_detail_user_arn" {
  type    = string
  default = "arn:aws:iam::876515858155:user/jsmyth"
  # 'arn:aws:iam::876515858155:user/mike'
}


query "aws_iam_user_input" {
  sql = <<EOQ
select
  title as label,
  arn as value
from
  aws_iam_user
order by
  title;
EOQ
}


### 
query "aws_iam_user_mfa_for_user" {
  sql = <<-EOQ
    select
      case when mfa_enabled then 'Enabled' else 'Disabled' end as value,
      'MFA Status' as label,
      case when mfa_enabled then 'ok' else 'alert' end as type
    from 
      aws_iam_user  
    where
      arn = 'arn:aws:iam::876515858155:user/jsmyth' --$1 
  EOQ

  # param "arn" {
  #   default = var.iam_detail_user_arn
  # }
}


#select jsonb_array_length(attached_policy_arns), jsonb_array_length(inline_policies) from aws_iam_user

### 
query "aws_iam_user_direct_attached_policy_count_for_user" {
  sql = <<-EOQ
    select
      jsonb_array_length(attached_policy_arns) as value,
      'Direct Attached Policies' as label,
      case when jsonb_array_length(attached_policy_arns) = 0 then 'ok' else 'alert' end as type
    from 
      aws_iam_user  
    where
      arn = 'arn:aws:iam::876515858155:user/jsmyth'
  EOQ
}

query "aws_iam_user_inline_policy_count_for_user" {
  sql = <<-EOQ
    select
      jsonb_array_length(inline_policies) as value,
      'Inline Policies' as label,
      case when jsonb_array_length(inline_policies) = 0 then 'ok' else 'alert' end as type
    from 
      aws_iam_user  
    where
      arn = 'arn:aws:iam::876515858155:user/jsmyth'
  EOQ

}


### 
query "aws_iam_boundary_policy_for_user" {
  sql = <<-EOQ
    select
      case 
        when permissions_boundary_type is null then 'Not Set' 
        when permissions_boundary_type = '' then 'Not Set' 
        else substring(permissions_boundary_arn, 'arn:aws:iam::\d{12}:.+\/(.*)') 
      end as value,
      'Boundary Policy' as label,
      case 
        when permissions_boundary_type is null then 'alert'
        when permissions_boundary_type = '' then 'alert'  
        else 'ok'
      end as type
    from 
      aws_iam_user  
    where
      arn = 'arn:aws:iam::876515858155:user/jsmyth' --$1 
      --arn = 'arn:aws:iam::876515858155:user/turbot/mike@turbot.com'
  EOQ

}
###


query "aws_iam_groups_for_user" {
  sql   = <<-EOQ
    select
      g ->> 'GroupName' as "Name",
      g ->> 'Arn' as "ARN",
      g ->> 'GroupId' as "Group ID"
    from
      aws_iam_user as u,
      jsonb_array_elements(groups) as g
    where
      u.arn = 'arn:aws:iam::876515858155:user/jsmyth'
  EOQ
}


query "aws_iam_all_policies_for_user" {
  sql = <<-EOQ

    -- Policies (attached to groups)
    select
      p.title as "Policy",
      p.arn as "ARN",
      'Group: ' || g.title as "Via"
    from
      aws_iam_user as u,
      aws_iam_policy as p,
      jsonb_array_elements(u.groups) as user_groups
      inner join aws_iam_group g on g.arn = user_groups ->> 'Arn'
    where
      g.attached_policy_arns :: jsonb ? p.arn
      and u.arn = 'arn:aws:iam::876515858155:user/jsmyth'


    -- Policies (inline from groups)
    union select
      i ->> 'PolicyName' as "Policy",
      'N/A' as "ARN",
      'Group: ' || grp.title || ' (inline)' as "Via"
    from
      aws_iam_user as u,
      jsonb_array_elements(u.groups) as g,
      aws_iam_group as grp,
      jsonb_array_elements(grp.inline_policies_std) as i

    where
      grp.arn = g ->> 'Arn'
      and u.arn = 'arn:aws:iam::876515858155:user/jsmyth'


    -- Policies (attached to user)
    union select
      p.title as "Policy",
      p.arn as "ARN",
      'Attached to User' as "Via"
    from
      aws_iam_user as u,
      jsonb_array_elements_text(u.attached_policy_arns) as pol_arn,
      aws_iam_policy as p
    where
      u.attached_policy_arns :: jsonb ? p.arn
      and pol_arn = p.arn
      and u.arn = 'arn:aws:iam::876515858155:user/jsmyth'


    -- Inline Policies (defined on user)
    union select
      i ->> 'PolicyName' as "Policy",
      'N/A' as "ARN",
      'Inline' as "Via"
    from
      aws_iam_user as u,
      jsonb_array_elements(inline_policies_std) as i
    where
      u.arn = 'arn:aws:iam::876515858155:user/jsmyth'


  EOQ

}

query "aws_iam_user_manage_policies_sankey" {
  sql = <<EOQ

    with args as (
        --select 'arn:aws:iam::876515858155:user/mike' as iam_user_arn
        --select 'arn:aws:iam::876515858155:user/smyth-steamcloud-test' as iam_user_arn
        select 'arn:aws:iam::876515858155:user/jsmyth' as iam_user_arn
    )

    -- the user ...
    select
      null as parent,
      arn as id,
      title as name,
      0 as depth,
      'aws_iam_user' as category
    from
      aws_iam_user
    where
      arn in (select iam_user_arn from args)

    -- Groups..
    union select
      u.arn as parent,
      g ->> 'Arn' as id,
      g ->> 'GroupName' as name,
      1 as depth,
      'aws_iam_group' as category
    from
      aws_iam_user as u,
      jsonb_array_elements(groups) as g
    where
      u.arn in (select iam_user_arn from args)


    -- Policies (attached to groups)
    union select
      g.arn as parent,
      p.arn as id,
      p.title as name,
      2 as depth,
      'aws_iam_policy' as category
    from
      aws_iam_user as u,
      aws_iam_policy as p,
      jsonb_array_elements(u.groups) as user_groups
      inner join aws_iam_group g on g.arn = user_groups ->> 'Arn'
    where
      g.attached_policy_arns :: jsonb ? p.arn
      and u.arn in (select iam_user_arn from args)

    -- Policies (inline from groups)
    union select
      grp.arn as parent,
      concat(grp.group_id, '_' , i ->> 'PolicyName') as id,
      concat(i ->> 'PolicyName', ' (inline)') as name,
      2 as depth,
      'inline_policy' as category
    from
      aws_iam_user as u,
      jsonb_array_elements(u.groups) as g,
      aws_iam_group as grp,
      jsonb_array_elements(grp.inline_policies_std) as i
    where
      grp.arn = g ->> 'Arn'
      and u.arn in (select iam_user_arn from args)


    -- Policies (attached to user)
    union select
      u.arn as parent,
      p.arn as id,
      p.title as name,
      2 as depth,
      'aws_iam_policy' as category
    from
      aws_iam_user as u,
      jsonb_array_elements_text(u.attached_policy_arns) as pol_arn,
      aws_iam_policy as p
    where
      u.attached_policy_arns :: jsonb ? p.arn
      and pol_arn = p.arn
      and u.arn in (select iam_user_arn from args)

    -- Inline Policies (defined on user)
    union select
      u.arn as parent,
      concat('inline_', i ->> 'PolicyName') as id,
      concat(i ->> 'PolicyName', ' (inline)') as name,
      2 as depth,
      'inline_policy' as category
    from
      aws_iam_user as u,
      jsonb_array_elements(inline_policies_std) as i
    where
      u.arn in (select iam_user_arn from args)


EOQ
}



report aws_iam_user_detail {
  title = "AWS IAM User Detail"

  input {
    title = "User"
    sql   = query.aws_iam_user_input.sql
    width = 2
  }

  container {

  
    #  # Analysis
    # card {
    #   #title = "Size"
    #   sql   = query.aws_vpc_num_ips_for_vpc.sql
    #   width = 2
    # }

    # Assessments
    card {
      sql = query.aws_iam_user_mfa_for_user.sql
      //query = query.aws_iam_user_mfa_for_user
      # param "arn" {
      #   default = var.iam_detail_user_arn
      # }
      width = 2
    }


    card {
      sql = query.aws_iam_boundary_policy_for_user.sql
      width = 2
    }


    card {
      sql = query.aws_iam_user_inline_policy_count_for_user.sql
      width = 2
    }

    card {
      sql = query.aws_iam_user_direct_attached_policy_count_for_user.sql
      width = 2
    }

    
  }




  container {
    # title = "Overiew"

    container {
      title = "Overview"

      table {
        width = 6 
        sql   = <<-EOQ
          select
            name as "Name",
            create_date as "Create Date",
            permissions_boundary_arn as "Boundary Policy",
            user_id as "User ID",
            arn as "ARN",
            account_id as "Account ID"
          from
            aws_iam_user
          where 
           arn = 'arn:aws:iam::876515858155:user/jsmyth'
        EOQ
      }



      table {
        title = "Tags"
        width = 6 

        sql   = <<-EOQ
          select
            tag ->> 'Key' as "Key",
            tag ->> 'Value' as "Value"
          from
            aws_iam_user,
            jsonb_array_elements(tags_src) as tag
          where 
            arn = 'arn:aws:iam::876515858155:user/jsmyth'
        EOQ
      }
    }

  }
  


    container {
      title = "Credentials"

      table {
        title = "Console"
        width = 4 
        sql   = <<-EOQ
          select
            name as "Name",
            create_date as "Create Date",
            password_last_used as "Password Last Used",
            mfa_enabled as "MFA Enabled"
          from
            aws_iam_user
          where 
           arn = 'arn:aws:iam::876515858155:user/jsmyth'
        EOQ
      }

      table {
        title = "Access Keys"
        width = 4
        sql   = <<-EOQ
          select
            k.access_key_id as "Access Key ID",
            k.status as "Status",
            k.create_date as "Create Date"    
          from
            aws_iam_user as u,
            aws_iam_access_key as k
          where 
            u.name = k.user_name
            and u.account_id = k.account_id 
            and arn = 'arn:aws:iam::876515858155:user/jsmyth'
        EOQ
      }

      table {
        title = "MFA Devices"
        width = 4
        sql   = <<-EOQ
          select
            mfa ->> 'SerialNumber' as "Serial Number",
            mfa ->> 'EnableDate' as "Enable Date",
            mfa ->> 'UserName' as "Username"
          from
            aws_iam_user as u,
            jsonb_array_elements(mfa_devices) as mfa
          where 
             arn = 'arn:aws:iam::876515858155:user/jsmyth'
        EOQ
      }

    }


  container {
    title = "AWS IAM User Analysis"

    # table {
    #   sql = query.aws_iam_user_manage_policies_sankey.sql

    #   column "parent" {
    #     wrap = "always"
    #   }
    #   column "id" {
    #     wrap = "always"
    #   }
    #   column "name" {
    #     wrap = "always"
    #   }
    #   column "depth" {
    #     display = "none"
    #   }
    #   column "category" {
    #     wrap = "always"
    #   }
    # }

    hierarchy {
      type  = "sankey"
      title = "Attached Policies"
      sql = query.aws_iam_user_manage_policies_sankey.sql

      category "aws_iam_group" {
        color = "green"
      }
    }

    hierarchy {
      type  = "tree"
      title = "Attached Policies"
      sql = query.aws_iam_user_manage_policies_sankey.sql
    }

    table {
      title = "Groups" 
      width = 6
      sql   = query.aws_iam_groups_for_user.sql
      
    }

    table {
      title = "Policies" 
      width = 6
      sql   = query.aws_iam_all_policies_for_user.sql

    }



  }

}