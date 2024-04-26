edge "opensearch_domain_to_acm_certificate" {
  title = "ssl via"

  sql = <<-EOQ
    select
      domain_endpoint_options ->> 'CustomEndpointCertificateArn' as to_id,
      arn as from_id
    from
      aws_opensearch_domain
    where
      domain_endpoint_options ->> 'CustomEndpointCertificateArn' = any($1);
  EOQ

  param "acm_certificate_arns" {}
}

edge "opensearch_domain_to_vpc_security_group" {
  title = "Security Groups"

  sql   = <<-EOQ
    select
      arn as from_id,
      jsonb_array_elements_text(vpc_options -> 'SecurityGroupIds') AS to_id
    from
      aws_opensearch_domain
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
      join jsonb_array_elements(vpc_options -> 'SecurityGroupIds') as s on true;
  EOQ

  param "opensearch_arn" {}
}

edge "opensearch_domain_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      jsonb_array_elements_text(vpc_options -> 'SecurityGroupIds') as from_id,
      jsonb_array_elements_text(vpc_options -> 'SubnetIds') AS to_id
    from
      aws_opensearch_domain
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
      join jsonb_array_elements(vpc_options -> 'SecurityGroupIds') as s on true;
  EOQ

  param "opensearch_arn" {}
}
