# AWS Insights

An AWS dashboarding tool that can be used to view dashboards and reports across all of your AWS accounts.

![image](https://raw.githubusercontent.com/turbot/steampipe-mod-aws-insights/release/v0.1/docs/images/aws_s3_bucket_dashboard.png)

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

## Getting started

### Installation

1) Download and install Steampipe (https://steampipe.io/downloads). Or use Brew:

```shell
brew tap turbot/tap
brew install steampipe

steampipe -v
steampipe version 0.13.0
```

2) Install the AWS plugin:

```shell
steampipe plugin install aws
```

3) Clone this repo:

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

## Contributing

If you have an idea for additional dashboards or reports, or just want to help maintain and extend this mod ([or others](https://github.com/topics/steampipe-mod)) we would love you to join the community and start contributing.

- **[Join our Slack community →](https://steampipe.io/community/join)** and hang out with other Mod developers.

Please see the [contribution guidelines](https://github.com/turbot/steampipe/blob/main/CONTRIBUTING.md) and our [code of conduct](https://github.com/turbot/steampipe/blob/main/CODE_OF_CONDUCT.md). All contributions are subject to the [Apache 2.0 open source license](https://github.com/turbot/steampipe-mod-aws-insights/blob/main/LICENSE).

`help wanted` issues:
- [Steampipe](https://github.com/turbot/steampipe/labels/help%20wanted)
- [AWS Insights Mod](https://github.com/turbot/steampipe-mod-aws-insights/labels/help%20wanted)
