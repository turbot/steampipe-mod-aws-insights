# AWS Insights Mod - Visualize and report on resource configuration across your AWS accounts

DevOps professionals use the AWS insights mod to visualize cloud intelligence and security metrics using interactive dashboards. Report on AWS resource configuration, visualize relationships, and aggregate metrics to better understand your cloud infrastructure. The dashboards are specified using a "low code" HCL format (similar to Terraform). Making it easy to inspect, modify and compose new dashboards to meet specific compliance and security objectives for your organization.

<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-aws-insights/main/docs/images/aws_insights_console_graphic.png" width="100%" alt="Screenshot of 'AWS S3 Bucket Dashboard' on 'pipes.turbot.com' with metrics on bucket privacy, encryption, logging, and costs."/> 

<figure class="figure">
  <img src="https://raw.githubusercontent.com/turbot/steampipe-mod-aws-insights/main/docs/images/aws_insights_console_graphic.png" class="figure-img img-fluid" alt="Screenshot of 'AWS S3 Bucket Dashboard' on 'pipes.turbot.com' with metrics on bucket privacy, encryption, logging, and costs."/>
  <figcaption class="figure-caption">'AWS S3 Bucket Dashboard' example using 'pipes.turbot.com' showing metrics on bucket privacy, encryption, logging, and costs.</figcaption>
</figure>

<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-aws-insights/main/docs/images/aws_s3_bucket_dashboard.png" width="50%" type="thumbnail" alt="Example of the 'AWS S3 Bucket Dashboard' with metrics on bucket privacy, encryption, logging, and costs."/>
<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-aws-insights/main/docs/images/aws_s3_bucket_detail.png" width="50%" type="thumbnail" alt="Detailed report for AWS S3 bucket 'ria-example-test'. Highlights: no public access, encryption on, logging off. Shows AWS service connections."/>
<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-aws-insights/main/docs/images/aws_ebs_snapshot_age.png" width="50%" type="thumbnail" alt="Dashboard for 'AWS EBS Snapshot Age Report' with filters like '<24 hours', '1-30 Days', and '>1 Year'. Table columns include Snapshot ID, Name, Age, and Region."/>
<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-aws-insights/main/docs/images/aws_ebs_volume_encryption.png" width="50%" type="thumbnail" alt="'AWS EBS Volume Encryption Report' dashboard highlighting 'Unencrypted' volumes. Table columns: Volume ID, Name, Encryption status, and Region."/>
<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-aws-insights/main/docs/images/aws_ec2_instance_public_access.png" width="50%" type="thumbnail" alt="'AWS EC2 Instance Public Access Report' from Steampipe showing 5 instances with 1 publicly accessible. Table includes Instance ID, Name, and access status."/>
<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-aws-insights/main/docs/images/aws_iam_policy_detail.png" width="50%" type="thumbnail" alt="Dashboard for 'AWS IAM Policy Detail' from Steampipe. Top section has a policy selector. Main section shows policy's relationships with AWS services."/>
<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-aws-insights/main/docs/images/aws_vpc_detail.png" width="50%" type="thumbnail" alt="Detailed dashboard of AWS VPC 'VPC Test' detailing relationships with resources like CIDR blocks, subnets, and security groups."/>
<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-aws-insights/main/docs/images/aws_vpc_security_group_detail.png" width="50%" type="thumbnail" alt="Visualization of AWS VPC Security Group 'default'. Details on ingress/egress rules and associated AWS connections."/>

## Overview

Resource type **Dashboards** have interactive elements that can answer questions like:

- How many of this resource type do I have?
- Counts by accounts and regions?
- Cost of these resources over time.
- Percentage of resources that are configured in specific ways (e.g. encryption on?)
- How old are my resources?

Resource **detail reports** can be reached by drilling down from dashboards or manually selecting the resource name.  They drill into a **specific resource** and can answer detailed configuration questions and provide a visualization of relationships to other resources. Use these to answer deep questions:
- What are the relationships between this resource and others?
- Is this resource publicly accessible?
- Is encryption enabled and what keys are used for encryption?
- Is versioning enabled?
- What networking ingress and egress rules are associated with this resource.


Dashboards are available for 15+ services, including CloudTrail, EC2, IAM, RDS, S3, VPC, and more!

## Documentation

- **[Dashboards →](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards)**

## Getting Started

### Installation

Download and install Steampipe (https://steampipe.io/downloads). Or use Brew:

```sh
brew tap turbot/tap
brew install steampipe
```

Install the AWS plugin with [Steampipe](https://steampipe.io):

```sh
steampipe plugin install aws
```

Clone:

```sh
git clone https://github.com/turbot/steampipe-mod-aws-insights.git
cd steampipe-mod-aws-insights
```

### Usage

Before running any dashboards, it's recommended to generate your AWS credential report:

```sh
aws iam generate-credential-report
```

Start your dashboard server to get started:

```sh
steampipe dashboard
```

By default, the dashboard interface will then be launched in a new browser window at http://localhost:9194. From here, you can view dashboards and reports.

### Credentials

This mod uses the credentials configured in the [Steampipe AWS plugin](https://hub.steampipe.io/plugins/turbot/aws).

### Configuration

No extra configuration is required.

## Open Source & Contributing

This repository is published under the [Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0). Please see our [code of conduct](https://github.com/turbot/.github/blob/main/CODE_OF_CONDUCT.md). We look forward to collaborating with you!

[Steampipe](https://steampipe.io) is a product produced from this open source software, exclusively by [Turbot HQ, Inc](https://turbot.com). It is distributed under our commercial terms. Others are allowed to make their own distribution of the software, but cannot use any of the Turbot trademarks, cloud services, etc. You can learn more in our [Open Source FAQ](https://turbot.com/open-source).

## Get Involved

**[Join #steampipe on Slack →](https://turbot.com/community/join)**

Want to help but don't know where to start? Pick up one of the `help wanted` issues:

- [Steampipe](https://github.com/turbot/steampipe/labels/help%20wanted)
- [AWS Insights Mod](https://github.com/turbot/steampipe-mod-aws-insights/labels/help%20wanted)
