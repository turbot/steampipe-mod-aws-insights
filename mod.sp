mod "aws_insights" {
  # hub metadata
  title         = "AWS Insights"
  description   = "Create dashboards and reports for your AWS resources using Steampipe."
  color         = "#FF9900"
  documentation = file("./docs/index.md")
  icon          = "/images/mods/turbot/aws-insights.svg"
  categories    = ["aws", "dashboard", "public cloud"]

  opengraph {
    title       = "Steampipe Mod for AWS Insights"
    description = "Create dashboards and reports for your AWS resources using Steampipe."
    image       = "/images/mods/turbot/aws-insights-social-graphic.png"
  }

  require {
    plugin "aws" {
      version = "0.50.1"
    }
    steampipe = "0.13.1"
  }
}
