locals {
  opensearch_common_tags = {
    service = "AWS/OpenSearch"
  }
}
category "opensearch_domain" {
  title = "OpenSearch Domain"
  color = local.analytics_color
  icon  = "search"
}
