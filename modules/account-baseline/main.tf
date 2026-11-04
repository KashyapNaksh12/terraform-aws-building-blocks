data "aws_partition" "current" {}

locals {
  partition = data.aws_partition.current.partition
}

# global settings, only create these from one region

resource "aws_iam_account_password_policy" "this" {
  count = var.manage_global_settings && var.password_policy != null ? 1 : 0

  minimum_password_length        = var.password_policy.minimum_length
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  password_reuse_prevention      = var.password_policy.reuse_prevention
  max_password_age               = var.password_policy.max_age_days
  hard_expiry                    = false
}

resource "aws_s3_account_public_access_block" "this" {
  count = var.manage_global_settings && var.s3_block_public_access ? 1 : 0

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_account_alias" "this" {
  count = var.manage_global_settings && var.account_alias != null ? 1 : 0

  account_alias = var.account_alias
}

resource "aws_account_alternate_contact" "this" {
  for_each = var.manage_global_settings ? var.alternate_contacts : {}

  alternate_contact_type = each.key
  name                   = each.value.name
  title                  = each.value.title
  email_address          = each.value.email
  phone_number           = each.value.phone
}

# CIS: a role for managing incidents with AWS Support
data "aws_iam_policy_document" "support_assume" {
  count = var.manage_global_settings && length(var.support_role_principals) > 0 ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = values(var.support_role_principals)
    }

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role" "support" {
  count = var.manage_global_settings && length(var.support_role_principals) > 0 ? 1 : 0

  name               = "aws-support"
  assume_role_policy = data.aws_iam_policy_document.support_assume[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "support" {
  count = var.manage_global_settings && length(var.support_role_principals) > 0 ? 1 : 0

  role       = aws_iam_role.support[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AWSSupportAccess"
}

# regional settings, create in every region you use

resource "aws_ebs_encryption_by_default" "this" {
  count = var.ebs_encryption_by_default ? 1 : 0

  enabled = true
}

resource "aws_ebs_default_kms_key" "this" {
  count = var.ebs_encryption_by_default && var.ebs_kms_key_arn != null ? 1 : 0

  key_arn = var.ebs_kms_key_arn
}

resource "aws_ec2_image_block_public_access" "this" {
  count = var.block_public_amis ? 1 : 0

  state = "block-new-sharing"
}

resource "aws_ec2_serial_console_access" "this" {
  count = var.disable_serial_console ? 1 : 0

  enabled = false
}

resource "aws_accessanalyzer_analyzer" "this" {
  count = var.access_analyzer != null ? 1 : 0

  analyzer_name = "${var.access_analyzer.name}-external"
  type          = var.access_analyzer.organization ? "ORGANIZATION" : "ACCOUNT"

  tags = var.tags
}

resource "aws_accessanalyzer_analyzer" "unused" {
  count = var.access_analyzer != null && try(var.access_analyzer.unused_access_age, null) != null ? 1 : 0

  analyzer_name = "${var.access_analyzer.name}-unused"
  type          = var.access_analyzer.organization ? "ORGANIZATION_UNUSED_ACCESS" : "ACCOUNT_UNUSED_ACCESS"

  configuration {
    unused_access {
      unused_access_age = var.access_analyzer.unused_access_age
    }
  }

  tags = var.tags
}
