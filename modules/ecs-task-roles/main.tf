locals {
  # secrets manager ARNs can carry a json-key suffix (arn:...:secret:name:key::),
  # IAM only matches the bare secret ARN
  secret_arns = distinct([
    for arn in values(var.secrets) : join(":", slice(split(":", arn), 0, 7))
    if strcontains(arn, ":secretsmanager:")
  ])
  parameter_arns = distinct([for arn in values(var.secrets) : arn if strcontains(arn, ":ssm:")])
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# execution role: used by the ECS agent to pull the image, write logs and
# fetch secrets before the container starts
resource "aws_iam_role" "execution" {
  name_prefix        = "${substr(var.name, 0, 26)}-exec-"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  for_each = merge(
    { ecs = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy" },
    var.execution_role_policy_arns,
  )

  role       = aws_iam_role.execution.name
  policy_arn = each.value
}

data "aws_iam_policy_document" "secrets" {
  count = length(var.secrets) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = length(local.secret_arns) > 0 ? [1] : []

    content {
      actions   = ["secretsmanager:GetSecretValue"]
      resources = local.secret_arns
    }
  }

  dynamic "statement" {
    for_each = length(local.parameter_arns) > 0 ? [1] : []

    content {
      actions   = ["ssm:GetParameters"]
      resources = local.parameter_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.secrets_kms_key_arns) > 0 ? [1] : []

    content {
      actions   = ["kms:Decrypt"]
      resources = values(var.secrets_kms_key_arns)
    }
  }
}

resource "aws_iam_role_policy" "secrets" {
  count = length(var.secrets) > 0 ? 1 : 0

  name   = "secrets"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.secrets[0].json
}

# task role: what the app itself can do
resource "aws_iam_role" "task" {
  name_prefix        = "${substr(var.name, 0, 26)}-task-"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "task" {
  for_each = var.task_role_policy_arns

  role       = aws_iam_role.task.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "task" {
  count = var.task_role_inline_policy != null ? 1 : 0

  name   = "inline"
  role   = aws_iam_role.task.id
  policy = var.task_role_inline_policy
}

data "aws_iam_policy_document" "exec" {
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "exec" {
  count = var.enable_execute_command ? 1 : 0

  name   = "ecs-exec"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.exec.json
}
