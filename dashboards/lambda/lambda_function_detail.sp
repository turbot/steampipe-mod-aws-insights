dashboard "aws_lambda_function_detail" {

  title = "AWS Lambda Function Detail"

  tags = merge(local.lambda_common_tags, {
    type = "Detail"
  })


  input "lambda_arn" {
    title = "Select a lambda function:"
    sql   = query.aws_lambda_function_input.sql
    width = 4
  }

  container {

    card {
      width = 2

      query = query.aws_lambda_function_memory
      args = {
        arn = self.input.lambda_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_lambda_function_runtime
      args = {
        arn = self.input.lambda_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_lambda_function_public
      args = {
        arn = self.input.lambda_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_lambda_function_encryption
      args = {
        arn = self.input.lambda_arn.value
      }
    }

    card {
      query = query.aws_lambda_function_in_vpc
      width = 2

      args = {
        arn = self.input.lambda_arn.value
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
        sql   = <<-EOQ
          select
            name as "Name",
            state as "State",
            vpc_id as "VPC ID",
            title as "Title",
            region as "Region",
            account_id as "Account ID",
            arn as "ARN"
          from
            aws_lambda_function
          where
            arn = $1;
          EOQ

        param "arn" {}

        args = {
          arn = self.input.lambda_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6

        sql = <<-EOQ
          with jsondata as (
            select
              tags::json as tags
            from
              aws_lambda_function
            where
              arn = $1
          )
          select
            key as "Key",
            value as "Value"
          from
            jsondata,
            json_each_text(tags)
          order by
            key;
          EOQ

        param "arn" {}

        args = {
          arn = self.input.lambda_arn.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "Last Update Status"
        query = query.aws_lambda_function_last_update_status
        args = {
          arn = self.input.lambda_arn.value
        }
      }
    }

  }

  container {

    width = 12

    table {
      title = "Policy"
      query = query.aws_lambda_function_policy
      args = {
        arn = self.input.lambda_arn.value
      }
    }

  }

  container {

    width = 6

    table {
      title = "Security Groups"
      query = query.aws_lambda_function_security_groups
      args = {
        arn = self.input.lambda_arn.value
      }
    }

  }

  container {

    width = 6

    table {
      title = "Subnets"
      query = query.aws_lambda_function_subnet_ids
      args = {
        arn = self.input.lambda_arn.value
      }
    }

  }

}

query "aws_lambda_function_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_lambda_function
    order by
      title;
  EOQ
}

query "aws_lambda_function_memory" {
  sql = <<-EOQ
    select
      'Memory' as label,
       round(cast(memory_size/1024 as numeric), 1) as value
    from
      aws_lambda_function
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_lambda_function_runtime" {
  sql = <<-EOQ
    select
      'Runtime' as label,
      'runtime' as value
    from
      aws_lambda_function
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_lambda_function_public" {
  sql = <<-EOQ
    select
      'Public' as label,
      case when
        policy_std -> 'Statement' ->> 'Effect' = 'Allow'
          and ( policy_std -> 'Statement' ->> 'Prinipal' = '*'
          or ( policy_std -> 'Principal' -> 'AWS' ) :: text = '*'
        )  then 'Enabled' else 'Disabled' end as value,
      case
      when
        policy_std -> 'Statement' ->> 'Effect' = 'Allow'
          and ( policy_std -> 'Statement' ->> 'Prinipal' = '*'
          or ( policy_std -> 'Principal' -> 'AWS' ) :: text = '*'
        )  then 'ok' else 'alert' end as type
    from
      aws_lambda_function
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_lambda_function_encryption" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when kms_key_arn is not null then 'Enabled' else 'Disabled' end as value,
      case when kms_key_arn is not null then 'ok' else 'alert' end as type
    from
      aws_lambda_function
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_lambda_function_in_vpc" {
  sql = <<-EOQ
    select
      'In VPC' as label,
      case when vpc_id is not null then 'Enabled' else 'Disabled' end as value,
      case when vpc_id is not null then 'ok' else 'alert' end as type
    from
      aws_lambda_function
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_lambda_function_last_update_status" {
  sql = <<-EOQ
    select
      last_modified  as "Last Modified",
      last_update_status as "Last Update Status",
      last_update_status_reason as "Last Update Status Reason",
      last_update_status_reason_code as "Last Update Status Reason Code"
    from
      aws_lambda_function
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_lambda_function_policy" {
  sql = <<-EOQ
    select
      p -> 'Action'  as "Action",
      p ->> 'Effect' as "Effect",
      p -> 'Principal' as "Principal",
      p -> 'Resource' as "Resource",
      p ->> 'Sid' as "SID"
    from
      aws_lambda_function,
      jsonb_array_elements(policy_std -> 'Statement') as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_lambda_function_security_groups" {
  sql = <<-EOQ
    select
      p as "ID"
    from
      aws_lambda_function,
      jsonb_array_elements(vpc_security_group_ids) as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_lambda_function_subnet_ids" {
  sql = <<-EOQ
    select
      p as "ID"
    from
      aws_lambda_function,
      jsonb_array_elements(vpc_subnet_ids) as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}


