dashboard "__icon_test" {

  container {
    card {
      width = 2
      icon  = "bell"
      type  = "alert"
      sql   = "select '0' as bell"
    }
    card {
      width = 2
      icon  = "heroicons-solid:bell"
      type  = "alert"
      sql   = <<-EOQ
        select '0' as "heroicons-solid:bell"
      EOQ
    }

    card {
      width = 2
      icon  = "exclamation"
      type  = "alert"
      sql   = "select '0' as exclamation"
    }
    card {
      width = 2
      icon  = "heroicons-solid:exclamation"
      type  = "alert"
      sql   = <<-EOQ
        select '0' as "heroicons-solid:exclamation"
      EOQ
    }

    card {
      width = 2
      icon  = "shield-exclamation"
      type  = "alert"
      sql   = <<-EOQ
        select '0' as "shield-exclamation"
      EOQ
    }

    card {
      width = 2
      icon  = "heroicons-solid:shield-exclamation"
      type  = "alert"
      sql   = <<-EOQ
        select '0' as "heroicons-solid:shield:exclamation"
      EOQ
    }

    card {
      width = 2
      icon  = "exclamation-circle"
      type  = "alert"
      sql   = <<-EOQ
        select '0' as "exclamation-circle"
      EOQ
    }
    
    card {
      width = 2
      icon  = "heroicons-solid:exclamation-circle"
      type  = "alert"
      sql   = <<-EOQ
        select '0' as "heroicons-solid:exclamation-circle"
      EOQ
    }

    card {
      width = 2
      icon  = "emoji-sad"
      type  = "alert"
      sql   = <<-EOQ
        select '0' as "emoji-sad"
      EOQ
    }
    
    card {
      width = 2
      icon  = "heroicons-solid:emoji-sad"
      type  = "alert"
      sql   = <<-EOQ
        select '0' as "heroicons-solid:emoji-sad"
      EOQ
    }

  }




  container {
    card {
      width = 2
      icon  = "heart"
      type  = "ok"
      sql   = "select '0' as heart"
    }
    card {
      width = 2
      icon  = "heroicons-solid:heart"
      type  = "ok"
      sql   = <<-EOQ
        select '0' as "heroicons-solid:heart"
      EOQ
    }

    card {
      width = 2
      icon  = "check"
      type  = "ok"
      sql   = "select '0' as check"
    }
    card {
      width = 2
      icon  = "heroicons-solid:check"
      type  = "ok"
      sql   = <<-EOQ
        select '0' as "heroicons-solid:check"
      EOQ
    }

    card {
      width = 2
      icon  = "shield-check"
      type  = "ok"
      sql   = <<-EOQ
        select '0' as "shield-check"
      EOQ
    }

    card {
      width = 2
      icon  = "heroicons-solid:shield-check"
      type  = "ok"
      sql   = <<-EOQ
        select '0' as "heroicons-solid:shield:check"
      EOQ
    }

    card {
      width = 2
      icon  = "check-circle"
      type  = "ok"
      sql   = <<-EOQ
        select '0' as "check-circle"
      EOQ
    }
    
    card {
      width = 2
      icon  = "heroicons-solid:check-circle"
      type  = "ok"
      sql   = <<-EOQ
        select '0' as "heroicons-solid:check-circle"
      EOQ
    }


    card {
      width = 2
      icon  = "emoji-happy"
      type  = "ok"
      sql   = <<-EOQ
        select '0' as "emoji-happy"
      EOQ
    }
    
    card {
      width = 2
      icon  = "heroicons-solid:emoji-happy"
      type  = "ok"
      sql   = <<-EOQ
        select '0' as "heroicons-solid:emoji-happy"
      EOQ
    }


  }

  container {
    card {
      width = 2
      icon  = "eye"
      type  = "info"
      sql   = <<-EOQ
        select '0' as "eye"
      EOQ
    }
  card {
      width = 2
      icon  = "heroicons-solid:eye"
      type  = "info"
      sql   = <<-EOQ
        select '0' as "heroicons-solid:eye"
      EOQ
    }


    
    card {
      width = 2
      icon  = "information-circle"
      type  = "info"
      sql   = <<-EOQ
        select '0' as "information-circle"
      EOQ
    }
    
    card {
      width = 2
      icon  = "heroicons-solid:information-circle"
      type  = "info"
      sql   = <<-EOQ
        select '0' as "heroicons-solid:information-circle"
      EOQ
    }

  }


   card {
      width = 2
      type  = "none"
      sql   = <<-EOQ
        select '0' as "none"
      EOQ
    }
  container {
 
    card {
      width = 2
      type  = "info"
      sql   = <<-EOQ
        select '0' as "info"
      EOQ
    }
      card {
      width = 2
      type  = "ok"
      sql   = <<-EOQ
        select '0' as "ok"
      EOQ
    }

   card {
      width = 2
      type  = "alert"
      sql   = <<-EOQ
        select '0' as "alert"
      EOQ
    }
  }

card {
      width = 2
      icon  = "heroicons-solid:information-circle"
      type  = "info"
      sql   = <<-EOQ
        select '0' as "heroicons-solid:information-circle"
      EOQ
    }

    card {
      width = 2
      icon  = "heroicons-solid:check-circle"
      type  = "ok"
      sql   = <<-EOQ
        select '0' as "heroicons-solid:check-circle"
      EOQ
    }
   card {
      width = 2
      icon  = "heroicons-solid:exclamation-circle"
      type  = "alert"
      sql   = <<-EOQ
        select '0' as "heroicons-solid:exclamation-circle"
      EOQ
    }


}

/*
 select
      count(*) as value,
      'Unattached Volumes' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type",
      case count(*) when 0 then 'check' else 'bell' end as "icon"

    from
      aws_ebs_volume
    where
      attachments is null

      */
