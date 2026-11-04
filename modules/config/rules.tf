# AWS managed rules that map to the usual SOC2 controls (logging, access, encryption, network, backups)
locals {
  default_rules = {
    cloudtrail-enabled             = { identifier = "CLOUD_TRAIL_ENABLED" }
    multi-region-cloudtrail        = { identifier = "MULTI_REGION_CLOUD_TRAIL_ENABLED" }
    cloudtrail-log-file-validation = { identifier = "CLOUD_TRAIL_LOG_FILE_VALIDATION_ENABLED" }
    cloudtrail-encrypted           = { identifier = "CLOUD_TRAIL_ENCRYPTION_ENABLED" }
    guardduty-enabled              = { identifier = "GUARDDUTY_ENABLED_CENTRALIZED" }
    securityhub-enabled            = { identifier = "SECURITYHUB_ENABLED" }
    kms-key-rotation               = { identifier = "CMK_BACKING_KEY_ROTATION_ENABLED" }

    s3-account-public-access-block = { identifier = "S3_ACCOUNT_LEVEL_PUBLIC_ACCESS_BLOCKS_PERIODIC" }
    s3-bucket-public-read          = { identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED" }
    s3-bucket-public-write         = { identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED" }
    s3-bucket-encryption           = { identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED" }
    s3-bucket-ssl-only             = { identifier = "S3_BUCKET_SSL_REQUESTS_ONLY" }

    ebs-encryption-by-default = { identifier = "EC2_EBS_ENCRYPTION_BY_DEFAULT" }
    ebs-volumes-encrypted     = { identifier = "ENCRYPTED_VOLUMES" }
    ec2-imdsv2                = { identifier = "EC2_IMDSV2_CHECK" }
    restricted-ssh            = { identifier = "INCOMING_SSH_DISABLED" }
    vpc-flow-logs-enabled     = { identifier = "VPC_FLOW_LOGS_ENABLED" }
    vpc-default-sg-closed     = { identifier = "VPC_DEFAULT_SECURITY_GROUP_CLOSED" }
    alb-http-to-https         = { identifier = "ALB_HTTP_TO_HTTPS_REDIRECTION_CHECK" }

    rds-storage-encrypted = { identifier = "RDS_STORAGE_ENCRYPTED" }
    rds-not-public        = { identifier = "RDS_INSTANCE_PUBLIC_ACCESS_CHECK" }
    rds-backup-enabled    = { identifier = "DB_INSTANCE_BACKUP_ENABLED" }
    dynamodb-pitr         = { identifier = "DYNAMODB_PITR_ENABLED" }
  }

  # IAM is global, only evaluate it where global resources are recorded
  default_global_rules = {
    root-account-mfa = { identifier = "ROOT_ACCOUNT_MFA_ENABLED" }
    root-access-key  = { identifier = "IAM_ROOT_ACCESS_KEY_CHECK" }
    iam-password-policy = {
      identifier = "IAM_PASSWORD_POLICY"
      input_parameters = {
        RequireUppercaseCharacters = "true"
        RequireLowercaseCharacters = "true"
        RequireSymbols             = "true"
        RequireNumbers             = "true"
        MinimumPasswordLength      = "14"
        PasswordReusePrevention    = "24"
        MaxPasswordAge             = "90"
      }
    }
    iam-console-mfa = { identifier = "MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS" }
    access-keys-rotated = {
      identifier       = "ACCESS_KEYS_ROTATED"
      input_parameters = { maxAccessKeyAge = "90" }
    }
    iam-unused-credentials = {
      identifier       = "IAM_USER_UNUSED_CREDENTIALS_CHECK"
      input_parameters = { maxCredentialUsageAge = "45" }
    }
    iam-no-admin-policies = { identifier = "IAM_POLICY_NO_STATEMENTS_WITH_ADMIN_ACCESS" }
    iam-user-no-policies  = { identifier = "IAM_USER_NO_POLICIES_CHECK" }
  }

  defaults = merge(
    local.default_rules,
    { for k, v in local.default_global_rules : k => v if var.include_global_resources },
  )

  rules = merge(
    {
      for k, v in local.defaults : k => {
        identifier       = v.identifier
        input_parameters = try(v.input_parameters, {})
        resource_types   = []
      } if var.default_rules_enabled && !contains(var.rules_disabled, k)
    },
    var.rules,
  )
}

resource "aws_config_config_rule" "this" {
  for_each = local.rules

  name             = "${var.name}-${each.key}"
  input_parameters = length(each.value.input_parameters) > 0 ? jsonencode(each.value.input_parameters) : null

  source {
    owner             = "AWS"
    source_identifier = each.value.identifier
  }

  dynamic "scope" {
    for_each = length(each.value.resource_types) > 0 ? [1] : []

    content {
      compliance_resource_types = each.value.resource_types
    }
  }

  tags = var.tags

  depends_on = [aws_config_configuration_recorder_status.this]
}

resource "aws_config_conformance_pack" "this" {
  for_each = var.conformance_packs

  name            = each.key
  template_body   = each.value.template_body
  template_s3_uri = each.value.template_s3_uri

  depends_on = [aws_config_configuration_recorder_status.this]
}
