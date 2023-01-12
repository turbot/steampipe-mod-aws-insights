dashboard "cloudfront_distribution_dashboard" {

  title         = "AWS CloudFront Distribution Dashboard"
  documentation = file("./dashboards/cloudfront/docs/cloudfront_distribution_dashboard.md")

  tags = merge(local.cloudfront_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.cloudfront_distribution_count
      width = 2
    }

    card {
      query = query.cloudfront_distribution_logging_disabled
      width = 2
    }

    card {
      query = query.cloudfront_distribution_sni_disabled
      width = 2
    }

    card {
      query = query.cloudfront_distribution_encryption_in_transit_disabled
      width = 2
    }

    card {
      query = query.cloudfront_distribution_waf_disabled
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Logging Status"
      query = query.cloudfront_distribution_logging_status
      type  = "donut"
      width = 3

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "SNI Status"
      query = query.cloudfront_distribution_sni_status
      type  = "donut"
      width = 3

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Encryption in Transit Status"
      query = query.cloudfront_distribution_encryption_in_transit_status
      type  = "donut"
      width = 3

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "WAF Status"
      query = query.cloudfront_distribution_waf_status
      type  = "donut"
      width = 3

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Distributions by Account"
      query = query.cloudfront_distribution_by_account
      type  = "column"
      width = 4
    }

    chart {
      title = "Distributions by Status"
      query = query.cloudfront_distribution_by_status
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "cloudfront_distribution_count" {
  sql = <<-EOQ
    select count(*) as "Distributions" from aws_cloudfront_distribution;
  EOQ
}

query "cloudfront_distribution_logging_disabled" {
  sql = <<-EOQ
    select
      'Logging Disabled' as label,
      count(*) as value,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_cloudfront_distribution
    where
      not (logging -> 'Enabled')::boolean;
  EOQ
}

query "cloudfront_distribution_sni_disabled" {
  sql = <<-EOQ
    select
      'SNI Disabled' as label,
      count(*) as value,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_cloudfront_distribution
    where
      viewer_certificate ->> 'SSLSupportMethod' <> 'sni-only';
  EOQ
}

query "cloudfront_distribution_encryption_in_transit_disabled" {
  sql = <<-EOQ
    select
      'Encryption in Transit Disabled' as label,
      count(*) as value,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_cloudfront_distribution
    where
      default_cache_behavior ->> 'ViewerProtocolPolicy' = 'allow-all';
  EOQ
}

query "cloudfront_distribution_waf_disabled" {
  sql = <<-EOQ
    select
      'WAF Disabled' as label,
      count(*) as value,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_cloudfront_distribution
    where
      web_acl_id = '';
  EOQ
}

# Assessments

query "cloudfront_distribution_logging_status" {
  sql = <<-EOQ
    select
      logging_status,
      count(*)
    from (
      select
        case when logging ->> 'Enabled' = 'false' then 'disabled' else 'enabled' end as logging_status
      from
        aws_cloudfront_distribution
    ) as d
    group by
      logging_status
    order by
      logging_status;
  EOQ
}

query "cloudfront_distribution_sni_status" {
  sql = <<-EOQ
    select
      sni_status,
      count(*)
    from (
      select
        case when viewer_certificate ->> 'SSLSupportMethod' <> 'sni-only' then 'disabled' else 'enabled' end as sni_status
      from
        aws_cloudfront_distribution
    ) as d
    group by
      sni_status
    order by
      sni_status;
  EOQ
}

query "cloudfront_distribution_encryption_in_transit_status" {
  sql = <<-EOQ
    select
      eit_status,
      count(*)
    from (
      select
        case when default_cache_behavior ->> 'ViewerProtocolPolicy' = 'allow-all' then 'disabled' else 'enabled' end as eit_status
      from
        aws_cloudfront_distribution
    ) as d
    group by
      eit_status
    order by
      eit_status;
  EOQ
}

query "cloudfront_distribution_waf_status" {
  sql = <<-EOQ
    select
      case when web_acl_id = '' then 'disabled' else 'enabled' end as waf_status,
      count(*)
    from
      aws_cloudfront_distribution
    group by
      waf_status
    order by
      waf_status;
  EOQ
}

# Analysis

query "cloudfront_distribution_by_account" {
  sql = <<-EOQ
    select
      a.title as "Account",
      count(d.*) as "Distributions"
    from
      aws_cloudfront_distribution as d,
      aws_account as a
    where
      a.account_id = d.account_id
    group by
      a.title
    order by
      a.title;
  EOQ
}

query "cloudfront_distribution_by_status" {
  sql = <<-EOQ
    select
      case when enabled then 'Enabled' else 'Disabled' end as "Status",
      count(*) as "Distributions"
    from
      aws_cloudfront_distribution
    group by "Status"
    order by "Status";
  EOQ
}
