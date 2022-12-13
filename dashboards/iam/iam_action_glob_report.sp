dashboard "iam_action_glob_report" {

  title = "AWS IAM Action Glob Report"

  tags = merge(local.iam_common_tags, {
    type     = "Report"
    category = "Security"
  })

  # input "action_glob" {
  #   type        = "text"
  #   title       = "Action:"
  #   placeholder = "Enter an action glob (e.g. ec2: desc*)"
  #   width       = 4
  # }

  container {

    card {
      query = query.iam_actions_for_glob_total_statements
      width = 2
      // Defaults
      label = "Permissions management"
      value = 0
      type  = "ok"

      args = {
        action_glob  = self.input.action_glob.value
        access_level = "Permissions management"
      }
    }

    card {
      query = query.iam_actions_for_glob_total_statements
      width = 2
      // Defaults
      label = "Write"
      value = 0
      type  = "ok"

      args = {
        action_glob  = self.input.action_glob.value
        access_level = "Write"
      }
    }

    card {
      query = query.iam_actions_for_glob_total_statements
      width = 2
      // Defaults
      label = "Read"
      value = 0
      type  = "ok"

      args = {
        action_glob  = self.input.action_glob.value
        access_level = "Read"
      }
    }

    card {
      query = query.iam_actions_for_glob_total_statements
      width = 2
      // Defaults
      label = "List"
      value = 0
      type  = "ok"

      args = {
        action_glob  = self.input.action_glob.value
        access_level = "List"
      }
    }


    card {
      query = query.iam_actions_for_glob_total_statements
      width = 2

      // Defaults
      label = "Tagging"
      value = 0
      type  = "ok"

      args = {
        action_glob  = self.input.action_glob.value
        access_level = "Tagging"
      }
    }

  }


  table {

    query = query.iam_actions_for_glob
    args = {
      action_glob = self.input.action_glob.value
    }
  }

}


query "iam_actions_for_glob" {

  sql = <<-EOQ

    select
      distinct on (action)
      action,
      description,
      access_level,
      prefix,
      privilege
    from
      aws_iam_action as a
    where
      a.action like lower(glob($1))
  EOQ

  param "action_glob" {}
}



query "iam_actions_for_glob_total_statements" {

  sql = <<-EOQ
      select
        count(distinct action) as value,
        $2 as label,
        case when count(*) = 0 then 'ok' else 'alert' end as type
      from
        aws_iam_action as a
      where
        a.action like lower(glob($1))
        and access_level = $2
      group by
        access_level
  EOQ

  param "action_glob" {}
  param "access_level" {}
}
