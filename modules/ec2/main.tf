data "aws_ssm_parameter" "al2023" {
  count = var.ami_id == null ? 1 : 0

  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-${var.architecture}"
}

data "aws_subnet" "this" {
  id = var.subnet_id
}

locals {
  ami_id = var.ami_id != null ? var.ami_id : nonsensitive(data.aws_ssm_parameter.al2023[0].value)

  instance_profile = var.create_iam_instance_profile ? aws_iam_instance_profile.this[0].name : var.iam_instance_profile
}

data "aws_iam_policy_document" "assume" {
  count = var.create_iam_instance_profile ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  count = var.create_iam_instance_profile ? 1 : 0

  name_prefix        = "${substr(var.name, 0, 30)}-"
  assume_role_policy = data.aws_iam_policy_document.assume[0].json

  tags = var.tags
}

data "aws_partition" "current" {}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.create_iam_instance_profile ? merge(
    { ssm_core = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore" },
    var.iam_role_policy_arns,
  ) : {}

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "this" {
  count = var.create_iam_instance_profile ? 1 : 0

  name_prefix = "${substr(var.name, 0, 30)}-"
  role        = aws_iam_role.this[0].name

  tags = var.tags
}

resource "aws_instance" "this" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.vpc_security_group_ids
  key_name                    = var.key_name
  associate_public_ip_address = var.associate_public_ip_address
  iam_instance_profile        = local.instance_profile
  monitoring                  = var.monitoring
  disable_api_termination     = var.disable_api_termination
  user_data                   = var.user_data
  user_data_replace_on_change = var.user_data_replace_on_change

  # IMDSv2 only
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    encrypted             = true
    kms_key_id            = var.kms_key_id
    delete_on_termination = true
    tags                  = merge(var.tags, { Name = "${var.name}-root" })
  }

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    # otherwise every new AL2023 release would recreate the instance
    ignore_changes = [ami]
  }
}

resource "aws_ebs_volume" "this" {
  for_each = var.ebs_volumes

  availability_zone = data.aws_subnet.this.availability_zone
  size              = each.value.size
  type              = each.value.type
  iops              = each.value.iops
  throughput        = each.value.throughput
  encrypted         = true
  kms_key_id        = var.kms_key_id

  tags = merge(var.tags, { Name = "${var.name}-${replace(each.key, "/dev/", "")}" })
}

resource "aws_volume_attachment" "this" {
  for_each = var.ebs_volumes

  device_name = each.key
  volume_id   = aws_ebs_volume.this[each.key].id
  instance_id = aws_instance.this.id
}

resource "aws_eip" "this" {
  count = var.create_eip ? 1 : 0

  domain   = "vpc"
  instance = aws_instance.this.id

  tags = merge(var.tags, { Name = var.name })
}
