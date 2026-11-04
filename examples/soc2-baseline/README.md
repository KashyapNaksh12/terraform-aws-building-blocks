# soc2-baseline

Account-level controls for a SOC2 audit in one region, with every alert going to one encrypted SNS topic.

| Module | What it covers | TSC |
|--------|----------------|-----|
| account-baseline | Password policy, S3 public access block, EBS encryption by default, Access Analyzer (external + unused access), security contact | CC6.1, CC6.2, CC6.3 |
| cloudtrail | Audit log of every API call, kept 7 years, tamper-evident, with alarms on root use, logins without MFA and IAM/network changes | CC7.2, CC7.3 |
| config | Resource configuration history and continuous checks against the baseline | CC7.1, CC8.1 |
| guardduty | Threat detection on CloudTrail, VPC flow, DNS, S3, EKS, RDS and EBS | CC7.2 |
| security-hub | FSBP and CIS 3.0 posture checks in one place | CC4.1, CC7.1 |
| inspector | CVE scanning of EC2, ECR images and Lambda | CC7.1 |
| backup | Daily and monthly backups of everything tagged `Backup = true`, failure alerts | A1.2, CC9.1 |

Terraform only covers the AWS side. Policies, access reviews, onboarding/offboarding, incident response, vendor management and so on are still on you, and so is showing the auditor these controls ran over the whole audit period.

```bash
cp terraform.tfvars.example terraform.tfvars   # set alert_email
terraform init
terraform apply
```

After apply:

- Confirm the SNS subscription email
- Turn on MFA for the root user and delete any root access keys (can't be done with Terraform)
- Tag what should be backed up with `Backup = true`
- Run the module set again in each other region you use, with `include_global_resources = false` on config and `manage_global_settings = false` on account-baseline. One multi-region trail is enough
- Trigger a test alarm to make sure alerts arrive: `aws cloudwatch set-alarm-state --alarm-name <name>-root-account-usage --state-value ALARM --state-reason test`

With AWS Organizations, it's better to run CloudTrail as an organization trail in the management account, send Config and CloudTrail to a log archive account, and make one account the delegated admin for GuardDuty, Security Hub and Inspector.

Cost: Config, GuardDuty, Security Hub and Inspector are billed by usage (resources, events, findings), so check the AWS pricing pages before turning this on in a big account. S3 data events on the trail and the unused access analyzer add to it.
