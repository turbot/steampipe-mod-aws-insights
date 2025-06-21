dashboard "lambda_function_inventory_report" {

  title         = "AWS Lambda Function Inventory Report"
  documentation = file("./dashboards/lambda/docs/lambda_function_report_inventory.md")

  tags = merge(local.lambda_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {

    card {
      query = query.lambda_function_count
      width = 2
    }

  }

  table {
    column "Name" {
      href = "${dashboard.lambda_function_detail.url_path}?input.function_name={{.'ARN' | @uri}}"
    }

    query = query.lambda_function_inventory_table
  }

}

query "lambda_function_inventory_table" {
  sql = <<-EOQ
    select
      f.name as "Name",
      f.last_modified as "Last Modified",
      f.runtime as "Runtime",
      f.memory_size as "Memory Size (MB)",
      f.timeout as "Timeout (sec)",
      f.handler as "Handler",
      f.package_type as "Package Type",
      f.role as "Execution Role",
      f.tags as "Tags",
      f.arn as "ARN",
      f.account_id as "Account ID",
      a.title as "Account",
      f.region as "Region"
    from
      aws_lambda_function as f
      left join aws_account as a on f.account_id = a.account_id
    order by
      f.name;
  EOQ
} 