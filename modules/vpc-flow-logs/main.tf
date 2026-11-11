resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/vpc/flow-logs/${var.name}"
  retention_in_days = var.retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name_prefix        = "${substr(var.name, 0, 20)}-flow-logs-"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = var.tags
}

data "aws_iam_policy_document" "this" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = ["${aws_cloudwatch_log_group.this.arn}:*"]
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "flow-logs"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.this.json
}

resource "aws_flow_log" "this" {
  vpc_id          = var.vpc_id
  traffic_type    = var.traffic_type
  log_destination = aws_cloudwatch_log_group.this.arn
  iam_role_arn    = aws_iam_role.this.arn

  tags = merge(var.tags, { Name = "${var.name}-flow-logs" })
}
