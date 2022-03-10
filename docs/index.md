---
repository: "https://github.com/turbot/steampipe-mod-aws-insights"
---

# AWS Insights Mod

Create dashboards and reports for your AWS resources using Steampipe.

<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-aws-insights/release/v0.1/docs/images/aws_s3_bucket_dashboard.png" width="50%" type="thumbnail"/>
<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-aws-insights/release/v0.1/docs/images/aws_ebs_snapshot_age.png" width="50%" type="thumbnail"/>
<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-aws-insights/release/v0.1/docs/images/aws_ebs_volume_encryption.png" width="50%" type="thumbnail"/>
<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-aws-insights/release/v0.1/docs/images/aws_ec2_instance_public_access.png" width="50%" type="thumbnail"/>
<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-aws-insights/release/v0.1/docs/images/aws_iam_role_detail.png" width="50%" type="thumbnail"/>
<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-aws-insights/release/v0.1/docs/images/aws_vpc_security_group_detail.png" width="50%" type="thumbnail"/>

## Overview

Dashboards can help answer questions like:

- How many resources do I have?
- How old are my resources?
- Are there any publicly accessible resources?
- Is encryption enabled and what keys are used for encryption?
- Is versioning enabled?
- What are the relationships between closely connected resources like IAM users, groups, and policies?

Dashboards are available for the following services:

- ACM
- CloudTrail
- DynamoDB
- EBS
- EC2
- IAM
- KMS
- Lambda
- RDS
- Redshift
- S3
- VPC
- And more!

## References

[AWS](https://aws.amazon.com/) provides on-demand cloud computing platforms and APIs to authenticated customers on a metered pay-as-you-go basis.

[Steampipe](https://steampipe.io) is an open source CLI to instantly query cloud APIs using SQL.

[Steampipe Mods](https://steampipe.io/docs/reference/mod-resources#mod) are collections of `named queries`, codified `controls` that can be used to test current configuration of your cloud resources against a desired configuration, and `dashboards` that organize and display key pieces of information.

## Documentation

- **[Benchmarks and controls →](https://hub.steampipe.io/mods/turbot/aws_insights/controls)**

## Getting started

### Installation

1) Install the AWS plugin:

```shell
steampipe plugin install aws
```

2) Clone this repo:

```sh
git clone https://github.com/turbot/steampipe-mod-aws-insights.git
cd steampipe-mod-aws-insights
```

### Usage

Start your dashboard server to get started:

```shell
steampipe dashboard
```

By default, the dashboard interface will then be launched in a new browser window at https://localhost:9194.

From here, you can view all of your dashboards and reports.

If there's a conflict on the default port 9194, the port can be changed with the `--dashboard-port` flag, e.g.,

```sh
steampipe dashboard --dashboard-port 9000
```

### Credentials

This mod uses the credentials configured in the [Steampipe AWS plugin](https://hub.steampipe.io/plugins/turbot/aws).

## Get involved

* Contribute: [GitHub Repo](https://github.com/turbot/steampipe-mod-aws-insights)

* Community: [Slack Channel](https://steampipe.io/community/join)
