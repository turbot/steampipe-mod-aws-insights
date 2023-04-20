
dashboard "secret_manager_inventory_dashboard" {

  title         = "AWS Secret Manager Inventory"
  #documentation = file("./dashboards/secret_manager/docs/secret_manager_inventory_dashboard.md")
  #tags = merge(local.secret_manager_common_tags, {
  #  type = "Inventory"
  # })

  # Cards
  container {
    card {
      title = "AWS Account with the most Secret Manager"
      query = query.secret_manager_top_by_account
      type  = "info"
      width = 4
    }

    card {
      title = "Total Secret Manager used"
      query = query.secret_manager_total
      type  = "info"
      width = 4
    }

    card {
      title = "Most used region"
      query = query.secret_manager_top_by_region
      type  = "info"
      width = 4
    }
 }

  # Details
  container {
    title = "Details"

    table {
      query = query.secret_manager_details
      width = 12
     
    }

  }
}

#---------------------------------------------------------------------------------------------------------
# Queries
#---------------------------------------------------------------------------------------------------------

# Cards
query "secret_manager_top_by_account" {
  sql = <<-EOQ
    Select
      account_id as label,
      COUNT(*) as value
    from
        aws_secretsmanager_secret
    group by
        account_id
    order by
        value DESC
    limit
        1
  EOQ
}

query "secret_manager_total" {
  sql = <<-EOQ
      select count(*) as "Total Secret Manager" from aws_secretsmanager_secret
  EOQ
}

query "secret_manager_top_by_region" {
  sql = <<-EOQ
    Select
      region as label,
      COUNT(*) as value
    from
      aws_secretsmanager_secret
    group by
        region
    order by
        value DESC
    limit
        1
  EOQ
}
# Details
query "secret_manager_details" {
  sql = <<-EOQ
    select  account_id as ENTORNO, region AS REGION,  name as SECRET_NAME, TO_CHAR(NOW(), 'MONTH') As FECHA, TO_CHAR(created_date at time zone 'utc' at time zone '-05','YYYY-MM-DD HH:MM') as CREATED_ON 
         ,  description as DESCRIPTION,   TO_CHAR(last_accessed_date at time zone 'utc' at time zone '-05','YYYY-MM-DD HH:MM')as LAST_RETRIEVED, replication_status,
            CASE WHEN primary_region IS NULL  THEN 'Not_replicated'
                 WHEN primary_region = region THEN 'Primary'
                 ELSE 'Replica'
                 END as REPLICATION_TYPE
         from  aws_secretsmanager_secret
  EOQ
}