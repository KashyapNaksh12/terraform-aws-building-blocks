resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.kms_key_arn != null ? "KMS" : "AES256"
    kms_key         = var.kms_key_arn
  }

  tags = var.tags
}

locals {
  lifecycle_rules = concat(
    var.untagged_image_expiry_days > 0 ? [{
      description = "Expire untagged images after ${var.untagged_image_expiry_days} days"
      tagStatus   = "untagged"
      countType   = "sinceImagePushed"
      countUnit   = "days"
      countNumber = var.untagged_image_expiry_days
    }] : [],
    var.max_image_count > 0 ? [{
      description = "Keep the last ${var.max_image_count} images"
      tagStatus   = "any"
      countType   = "imageCountMoreThan"
      countUnit   = null
      countNumber = var.max_image_count
    }] : [],
  )
}

resource "aws_ecr_lifecycle_policy" "this" {
  count = length(local.lifecycle_rules) > 0 ? 1 : 0

  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      for i, r in local.lifecycle_rules : {
        rulePriority = i + 1
        description  = r.description
        selection = { for k, v in {
          tagStatus   = r.tagStatus
          countType   = r.countType
          countUnit   = r.countUnit
          countNumber = r.countNumber
        } : k => v if v != null }
        action = { type = "expire" }
      }
    ]
  })
}

data "aws_iam_policy_document" "this" {
  count = length(var.read_access_arns) + length(var.read_write_access_arns) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = length(var.read_access_arns) > 0 ? [1] : []

    content {
      sid = "ReadOnly"
      actions = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecr:GetDownloadUrlForLayer",
      ]

      principals {
        type        = "AWS"
        identifiers = var.read_access_arns
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.read_write_access_arns) > 0 ? [1] : []

    content {
      sid = "ReadWrite"
      actions = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart",
      ]

      principals {
        type        = "AWS"
        identifiers = var.read_write_access_arns
      }
    }
  }
}

resource "aws_ecr_repository_policy" "this" {
  count = length(data.aws_iam_policy_document.this) > 0 ? 1 : 0

  repository = aws_ecr_repository.this.name
  policy     = data.aws_iam_policy_document.this[0].json
}
