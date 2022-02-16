query "aws_iam_user_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Total Users' as label
    from 
      aws_iam_user    
  EOQ
}

query "aws_iam_user_mfa_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'MFA Not Enabled' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from 
      aws_iam_user  
    where
      not mfa_enabled  
  EOQ
}


### 
query "aws_iam_users_by_account" {
  sql = <<-EOQ
    select 
      account_id,
      count(*)
    from 
      aws_iam_user
    group by 
      account_id
    order by
      count desc
  EOQ
}


####

query "aws_iam_users_by_mfa_enabled" {
  sql = <<-EOQ
    with mfa as (
      select
        case when mfa_enabled then 'Enabled' else 'Disabled' end as mfa_status
      from
        aws_iam_user
    )
    select
      mfa_status,
      count(mfa_status)
    from 
      mfa
    group by 
      mfa_status
  EOQ
}



report aws_iam_user_dashboard {
  title = "AWS IAM User Dashboard"

  
  container {

  
     # Analysis
    card {
      #title = "Size"
      sql   = query.aws_iam_user_count.sql
      width = 2
    }

    # #    # Assessments
    card {
      #title = "Subnet Count"
      sql   = query.aws_iam_user_mfa_count.sql
      width = 2
    }

    # card {
    #   sql   = query.aws_vpc_is_default.sql
    #   width = 2
    # }

    # card {
    #   sql = query.aws_flowlogs_count_for_vpc.sql
    #   width = 2
    # }
  }

  container {
    title = "Analysis"

    chart {
      title = "Users by Account"
      sql   = query.aws_iam_users_by_account.sql
      type  = "column"
      width = 3
    }
  }






  container {
    title = "Assessments"

    chart {
      title = "MFA Status"
      sql   = query.aws_iam_users_by_mfa_enabled.sql
      type  = "donut"
      width = 3

      # series "mfa_status" {
      #   point "Enabled" {
      #     color = "ok"
      #   }
      #   point "Disabled" {
      #     color = "alert"
      #   }
      # }
    }
  }
  

  
}