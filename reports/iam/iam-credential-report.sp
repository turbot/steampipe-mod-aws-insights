
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
          user_name,
          user_arn,

          password_enabled,
          mfa_active,
          password_status,
          date_trunc('day',age(now(),password_last_changed))::text as password_age,
          password_last_changed,
          password_last_used,
          password_next_rotation,


          access_key_1_active,
          date_trunc('day',age(now(),access_key_1_last_rotated))::text as access_key_1_age,
          access_key_1_last_rotated,
          access_key_1_last_used_date,
          access_key_1_last_used_region,
          access_key_1_last_used_service,

          access_key_2_active,
          date_trunc('day',age(now(),access_key_2_last_rotated))::text as access_key_2_age,
          access_key_2_last_rotated,
          access_key_2_last_used_date,
          access_key_2_last_used_region,
          access_key_2_last_used_service,

          cert_1_active,
          date_trunc('day',age(now(),cert_1_last_rotated))::text as cert_1_age,
          cert_1_last_rotated,

          cert_2_active,
          date_trunc('day',age(now(),cert_2_last_rotated))::text as cert_2_age,
          cert_2_last_rotated,

          a.title as account,
          r.account_id
          
        from 
          aws_iam_credential_report as r,
          aws_account as a
        where
          a.account_id = r.account_id


      
      EOQ
    }

  }
  

}
