locals {
  is_image   = var.image_uri != null
  is_vpc     = length(var.subnet_ids) > 0
  zip_source = var.source_dir != null ? data.archive_file.this[0].output_path : var.filename
  zip_hash   = var.source_dir != null ? data.archive_file.this[0].output_base64sha256 : (var.filename != null ? filebase64sha256(var.filename) : null)
}

data "archive_file" "this" {
  count = var.source_dir != null ? 1 : 0

  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.root}/.terraform/lambda-builds/${var.function_name}.zip"
}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name_prefix        = "${substr(var.function_name, 0, 30)}-"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = merge(
    { basic = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" },
    local.is_vpc ? { vpc = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole" } : {},
    var.tracing_mode != null ? { xray = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AWSXRayDaemonWriteAccess" } : {},
    var.policy_arns,
  )

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "this" {
  count = var.inline_policy != null ? 1 : 0

  name   = "inline"
  role   = aws_iam_role.this.id
  policy = var.inline_policy
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description
  role          = aws_iam_role.this.arn
  architectures = var.architectures
  memory_size   = var.memory_size
  timeout       = var.timeout

  reserved_concurrent_executions = var.reserved_concurrent_executions

  package_type     = local.is_image ? "Image" : "Zip"
  image_uri        = var.image_uri
  filename         = local.is_image ? null : local.zip_source
  s3_bucket        = local.is_image ? null : var.s3_bucket
  s3_key           = local.is_image ? null : var.s3_key
  source_code_hash = local.is_image ? null : local.zip_hash
  handler          = local.is_image ? null : var.handler
  runtime          = local.is_image ? null : var.runtime

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []

    content {
      variables = var.environment_variables
    }
  }

  dynamic "vpc_config" {
    for_each = local.is_vpc ? [1] : []

    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  dynamic "tracing_config" {
    for_each = var.tracing_mode != null ? [1] : []

    content {
      mode = var.tracing_mode
    }
  }

  tags = var.tags

  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy_attachment.this,
  ]

  lifecycle {
    precondition {
      condition = length(compact([
        var.source_dir,
        var.filename,
        var.image_uri,
        var.s3_bucket,
      ])) == 1
      error_message = "Set exactly one code source: source_dir, filename, image_uri, or s3_bucket (+ s3_key)."
    }
  }
}
