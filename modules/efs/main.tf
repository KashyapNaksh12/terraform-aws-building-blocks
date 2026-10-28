resource "aws_efs_file_system" "this" {
  creation_token   = var.name
  encrypted        = true
  kms_key_id       = var.kms_key_arn
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode
  # only valid with provisioned throughput
  provisioned_throughput_in_mibps = var.throughput_mode == "provisioned" ? var.provisioned_throughput_in_mibps : null

  dynamic "lifecycle_policy" {
    for_each = var.transition_to_ia != null ? [1] : []

    content {
      transition_to_ia = var.transition_to_ia
    }
  }

  dynamic "lifecycle_policy" {
    for_each = var.transition_to_archive != null ? [1] : []

    content {
      transition_to_archive = var.transition_to_archive
    }
  }

  dynamic "lifecycle_policy" {
    for_each = var.transition_to_primary_storage_class != null ? [1] : []

    content {
      transition_to_primary_storage_class = var.transition_to_primary_storage_class
    }
  }

  protection {
    replication_overwrite = var.replication_overwrite_protection ? "ENABLED" : "DISABLED"
  }

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = var.enable_backup ? "ENABLED" : "DISABLED"
  }
}

# one per AZ, keyed by a static name so subnet IDs can be unknown at plan time
resource "aws_efs_mount_target" "this" {
  for_each = var.mount_target_subnet_ids

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = var.security_group_ids
}

resource "aws_efs_access_point" "this" {
  for_each = var.access_points

  file_system_id = aws_efs_file_system.this.id

  posix_user {
    uid            = each.value.uid
    gid            = each.value.gid
    secondary_gids = each.value.secondary_gids
  }

  root_directory {
    path = each.value.path

    creation_info {
      owner_uid   = each.value.uid
      owner_gid   = each.value.gid
      permissions = each.value.permissions
    }
  }

  tags = merge(var.tags, { Name = "${var.name}-${each.key}" })
}

data "aws_iam_policy_document" "this" {
  source_policy_documents = var.policy != null ? [var.policy] : []

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["*"]
    resources = [aws_efs_file_system.this.arn]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # without an allow, a file system policy blocks all NFS clients
  statement {
    sid = "AllowMountThroughTargets"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientRootAccess",
    ]
    resources = [aws_efs_file_system.this.arn]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "elasticfilesystem:AccessedViaMountTarget"
      values   = ["true"]
    }
  }
}

resource "aws_efs_file_system_policy" "this" {
  file_system_id = aws_efs_file_system.this.id
  policy         = data.aws_iam_policy_document.this.json
}
