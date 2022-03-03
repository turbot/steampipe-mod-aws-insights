dashboard "aws_kms_key_detail" {

  title = "AWS KMS Key Detail"

  tags = merge(local.kms_common_tags, {
    type = "Detail"
  })


  input "key_arn" {
    title = "Select a key:"
    sql   = query.aws_kms_key_input.sql
    width = 4
  }

  container {

    card {
      width = 2

      query = query.aws_kms_key_type
      args = {
        arn = self.input.key_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_kms_key_enabled
      args = {
        arn = self.input.key_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_kms_key_state
      args = {
        arn = self.input.key_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_kms_key_rotation_enabled
      args = {
        arn = self.input.key_arn.value
      }
    }

    card {
      query = query.aws_kms_key_origin
      width = 2

      args = {
        arn = self.input.key_arn.value
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
            'id' as "Id",
            creation_date as "Creation Date",
            title as "Title",
            region as "Region",
            account_id as "Account Id",
            arn as "ARN"
          from
            aws_kms_key
          where
            arn = $1
          EOQ

        param "arn" {}

        args = {
          arn = self.input.key_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        sql = <<-EOQ
          select
            tag ->> 'Key' as "Key",
            tag ->> 'Value' as "Value"
          from
            aws_kms_key,
            jsonb_array_elements(tags_src) as tag
          where
            arn = $1
          EOQ

        param "arn" {}

        args = {
          arn = self.input.key_arn.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "Key Age"
        query = query.aws_kms_key_age
        args = {
          arn = self.input.key_arn.value
        }
      }

    }

  }

  container {

    width = 12

    table {
      title = "Policy"
      query = query.aws_kms_key_policy
      args = {
        arn = self.input.key_arn.value
      }
    }

  }

  container {

    width = 12

    table {
      title = "Key Aliases"
      query = query.aws_kms_key_aliases
      args = {
        arn = self.input.key_arn.value
      }
    }

  }

}

query "aws_kms_key_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_kms_key
    where
      key_manager = 'CUSTOMER'
    order by
      title;
  EOQ
}

query "aws_kms_key_type" {
  sql = <<-EOQ
    select
      'Key Manager' as label,
      key_manager as value
    from
      aws_kms_key
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_kms_key_origin" {
  sql = <<-EOQ
    select
      'Origin' as label,
      origin as value
    from
      aws_kms_key
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_kms_key_enabled" {
  sql = <<-EOQ
    select
      'Enabled' as label,
      case when enabled then 'Enabled' else 'Disabled' end as value,
      case when enabled then 'ok' else 'alert' end as "type"
    from
      aws_kms_key
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_kms_key_state" {
  sql = <<-EOQ
    select
      'State' as label,
      key_state as value,
      case when key_state = 'Enabled' then 'ok' else 'alert' end as "type"
    from
      aws_kms_key
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_kms_key_rotation_enabled" {
  sql = <<-EOQ
    select
      'Key Rotation' as label,
      case when key_rotation_enabled then 'Enabled' else 'Disabled' end as value,
      case when key_rotation_enabled then 'ok' else 'alert' end as type
    from
      aws_kms_key
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_kms_key_age" {
  sql = <<-EOQ
    select
      creation_date  as "Creation Date",
      deletion_date as "Deletion Date",
      extract(day from deletion_date - current_date)::int as "Deleting After Days"
    from
      aws_kms_key
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_kms_key_aliases" {
  sql = <<-EOQ
    select
      p ->> 'AliasArn'  as "Alias Arn",
      p ->> 'AliasName' as "Alias Name",
      p ->> 'CreationDate' as "Creation Date",
      p ->> 'LastUpdatedDate' as "Last Updated Date",
      p ->> 'TargetKeyId' as "Target Key Id"
    from
      aws_kms_key,
      jsonb_array_elements(aliases) as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_kms_key_policy" {
  sql = <<-EOQ
    select
      p -> 'Action'  as "Action",
      p -> 'Condition' as "Condition",
      p ->> 'Effect' as "Effect",
      p -> 'Principal' as "Principal",
      p -> 'Resource' as "Resource",
      p ->> 'Sid' as "Sid"
    from
      aws_kms_key,
      jsonb_array_elements(policy_std -> 'Statement') as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}