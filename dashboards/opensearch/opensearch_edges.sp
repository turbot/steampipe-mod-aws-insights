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


edge "opensearch_domain_name_to_vpc_security_group" {
  title = "Security Groups"
  sql = <<-EOQ
    SELECT
      s ->> 'GroupId' as from_id,
      jsonb_array_elements_text(vpc_options -> 'SecurityGroupIds') AS to_id
    FROM
      aws_opensearch_domain
      JOIN jsonb_array_elements(vpc_options -> 'SecurityGroupIds') AS s ON true
    WHERE
      domain_name = $1;
  EOQ
  param "opensearch_domain_name" {}
}



edge "opensearch_domain_name_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    SELECT
      s ->> 'GroupId' as from_id,
      jsonb_array_elements_text(vpc_options -> 'SubnetIds') AS to_id
    FROM
      aws_opensearch_domain
      JOIN jsonb_array_elements(vpc_options -> 'SecurityGroupIds') AS s ON true
    WHERE
      domain_name = $1;
  EOQ

  param "opensearch_domain_name" {}
}
