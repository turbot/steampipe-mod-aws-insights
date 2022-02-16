
dashboard "aws_iam_credential_report" {
  title = "AWS IAM Credential Report"

  text {
      value = <<-EOT
      ### Note 
      This report requires an [AWS Credential Report](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html) for each account.
      You can generate a credential report via the AWS CLI:

      EOT
  }

    text {
      width = 3
      value = <<-EOT
      ```bash
      aws iam generate-credential-report
      ```
      EOT
  }

  container {

    // TO DO - either add more cards (with passwrd and no mfa, password never used, keys over 90 days. etc)
    // or get rid of the cards altogether (they dont work unless there is a vred report for EVERY account in the aggregator)
     # Analysis
    card {
      sql   = <<-EOQ
        select 
          count(*) as value,
          'Total Entities' as label
        from 
          aws_iam_credential_report
      EOQ
      width = 2
    }

    # Assessments
    card {
      sql   = <<-EOQ
        select 
          count(*) as value,
          'Cosole Access & No MFA' as label,
          case when count(*) = 0 then 'ok' else 'alert' end as type
        from 
          aws_iam_credential_report
          where 
            password_enabled	 
            and not mfa_active
      EOQ
      width = 2
    }
  }


  container {


   table {
      title = "Accounts with Root Access Keys"

      sql   = <<-EOQ
        select
          user_name as "Username",
          user_arn as "User ARN",

          password_enabled as "Password Enabled",
          mfa_active as "MFA Active",
          password_status as "Password Status",
          date_trunc('day',age(now(),password_last_changed))::text as "Password Age",
          password_last_changed as "Password Changed Timestamp",
          date_trunc('day',age(now(),password_last_used))::text as "Password Last Used",
          password_last_used as "Password Last Used Timestamp",
          date_trunc('day',age(now(),password_next_rotation))::text as "Next Password Rotation",
          password_next_rotation "Next Password Rotation Timestamp",

          access_key_1_active as "Access Key 1 Active",
          date_trunc('day',age(now(),access_key_1_last_rotated))::text as "Key 1 Age",
          access_key_1_last_rotated as "Key 1 Last Rotated",
          date_trunc('day',age(now(),access_key_1_last_used_date))::text as  "Key 1 Last Used",
          access_key_1_last_used_date as "Key 1 Last Used Timestamp",
          access_key_1_last_used_region as "Key 1 Last Used Region",
          access_key_1_last_used_service as "Key 1 Last Used Service",

          access_key_2_active as "Access Key 2 Active",
          date_trunc('day',age(now(),access_key_2_last_rotated))::text as "Key 2 Age",
          access_key_2_last_rotated as "Key 2 Last Rotated Timestamp",
          date_trunc('day',age(now(),access_key_2_last_used_date))::text as  "Key 2 Last Used",
          access_key_2_last_used_date as "Key 2 Last Used Timestamp",
          access_key_2_last_used_region as "Key 2 Last Used Region",
          access_key_2_last_used_service as "Key 2 Last Used Service",

          cert_1_active as "Cert 1 Active",
          date_trunc('day',age(now(),cert_1_last_rotated))::text as "Cert 1 Age",
          cert_1_last_rotated "Cert 1 Last Rotated",

          cert_2_active,
          date_trunc('day',age(now(),cert_2_last_rotated))::text as "Cert 2 Age",
          cert_2_last_rotated as "Cert 2 Last Rotated",

          a.title as "Account",
          r.account_id as "Account ID"
          
        from 
          aws_iam_credential_report as r,
          aws_account as a
        where
          a.account_id = r.account_id


      
      EOQ
    }

  }
  

}
