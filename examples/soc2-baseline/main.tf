locals {
  name = "${var.name}-${var.environment}"
  tags = {
    Owner      = "devops"
    Compliance = "soc2"
  }
}

# one key for the audit trail, Config, backups and the alert topic
data "aws_iam_policy_document" "kms_alerts" {
  # CloudWatch alarms and EventBridge publish to the encrypted topic
  statement {
    sid       = "AlertPublishers"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey*"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com", "events.amazonaws.com"]
    }
  }
}

module "kms" {
  source = "../../modules/kms"

  alias       = "${local.name}-audit"
  description = "${local.name} audit logs, backups and alerts"

  allow_cloudwatch_logs = true
  service_principals = {
    cloudtrail = "cloudtrail.amazonaws.com"
  }
  policy = data.aws_iam_policy_document.kms_alerts.json

  tags = local.tags
}

module "alerts" {
  source = "../../modules/sns"

  name        = "${local.name}-security-alerts"
  kms_key_arn = module.kms.key_arn

  publisher_service_principals = {
    cloudwatch = "cloudwatch.amazonaws.com"
    events     = "events.amazonaws.com"
  }

  subscriptions = var.alert_email != null ? {
    email = {
      protocol = "email"
      endpoint = var.alert_email
    }
  } : {}

  tags = local.tags
}

# CC6: access control
module "account_baseline" {
  source = "../../modules/account-baseline"

  alternate_contacts = var.security_contact != null ? { SECURITY = var.security_contact } : {}

  access_analyzer = {
    name              = local.name
    unused_access_age = 90
  }

  tags = local.tags
}

# CC7.2: audit logging and alerting on risky changes
module "cloudtrail" {
  source = "../../modules/cloudtrail"

  name          = local.name
  kms_key_arn   = module.kms.key_arn
  alarm_actions = [module.alerts.topic_arn]

  tags = local.tags
}

# CC7.1 / CC8.1: configuration history and drift from the baseline
module "config" {
  source = "../../modules/config"

  name        = local.name
  kms_key_arn = module.kms.key_arn

  tags = local.tags
}

# CC7.2 / CC7.3: threat detection, posture findings and vulnerabilities
module "guardduty" {
  source = "../../modules/guardduty"

  name          = local.name
  notifications = { sns_topic_arn = module.alerts.topic_arn }

  tags = local.tags
}

module "security_hub" {
  source = "../../modules/security-hub"

  name          = local.name
  notifications = { sns_topic_arn = module.alerts.topic_arn }

  tags = local.tags

  # controls look at Config, so start after it
  depends_on = [module.config]
}

module "inspector" {
  source = "../../modules/inspector"

  name          = local.name
  notifications = { sns_topic_arn = module.alerts.topic_arn }

  tags = local.tags
}

# A1.2: backups of everything tagged Backup = true
module "backup" {
  source = "../../modules/backup"

  name          = local.name
  kms_key_arn   = module.kms.key_arn
  notifications = { sns_topic_arn = module.alerts.topic_arn }

  tags = local.tags
}
