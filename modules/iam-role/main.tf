locals {
  github_oidc_provider_arn = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.github_oidc_provider_arn
  enable_github_oidc       = length(var.github_oidc_subjects) > 0
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  tags = var.tags
}

data "aws_iam_policy_document" "assume" {
  count = var.assume_role_policy == null ? 1 : 0

  dynamic "statement" {
    for_each = length(var.trusted_services) > 0 ? [1] : []

    content {
      sid     = "TrustedServices"
      actions = ["sts:AssumeRole"]

      principals {
        type        = "Service"
        identifiers = var.trusted_services
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.trusted_role_arns) > 0 ? [1] : []

    content {
      sid     = "TrustedPrincipals"
      actions = ["sts:AssumeRole", "sts:TagSession"]

      principals {
        type        = "AWS"
        identifiers = var.trusted_role_arns
      }
    }
  }

  dynamic "statement" {
    for_each = local.enable_github_oidc ? [1] : []

    content {
      sid     = "GitHubActionsOIDC"
      actions = ["sts:AssumeRoleWithWebIdentity"]

      principals {
        type        = "Federated"
        identifiers = [local.github_oidc_provider_arn]
      }

      condition {
        test     = "StringEquals"
        variable = "token.actions.githubusercontent.com:aud"
        values   = ["sts.amazonaws.com"]
      }

      condition {
        test     = "StringLike"
        variable = "token.actions.githubusercontent.com:sub"
        values   = var.github_oidc_subjects
      }
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = var.name
  description          = var.description
  path                 = var.path
  max_session_duration = var.max_session_duration
  permissions_boundary = var.permissions_boundary_arn
  assume_role_policy   = var.assume_role_policy != null ? var.assume_role_policy : data.aws_iam_policy_document.assume[0].json

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.assume_role_policy != null || length(var.trusted_services) > 0 || length(var.trusted_role_arns) > 0 || local.enable_github_oidc
      error_message = "Provide assume_role_policy or at least one of trusted_services, trusted_role_arns, github_oidc_subjects."
    }

    precondition {
      condition     = !local.enable_github_oidc || local.github_oidc_provider_arn != null
      error_message = "github_oidc_subjects requires github_oidc_provider_arn or create_github_oidc_provider = true."
    }
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.managed_policy_arns

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "this" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.id
  policy = each.value
}

resource "aws_iam_instance_profile" "this" {
  count = var.create_instance_profile ? 1 : 0

  name = var.name
  path = var.path
  role = aws_iam_role.this.name

  tags = var.tags
}
