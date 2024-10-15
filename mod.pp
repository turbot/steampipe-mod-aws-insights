mod "aws_insights" {
  # Hub metadata
  title         = "AWS Insights"
  description   = "Create dashboards and reports for your AWS resources using Powerpipe and Steampipe."
  color         = "#FF9900"
  documentation = file("./docs/index.md")
  icon          = "/images/mods/turbot/aws-insights.svg"
  categories    = ["aws", "dashboard", "public cloud"]

  opengraph {
    title       = "Powerpipe Mod for AWS Insights"
    description = "Create dashboards and reports for your AWS resources using Powerpipe and Steampipe."
    image       = "/images/mods/turbot/aws-insights-social-graphic.png"
  }

  require {
    plugin "aws" {
      min_version = "0.91.0"
    }
  }
}
