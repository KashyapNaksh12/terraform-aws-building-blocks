data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "${var.name}-${var.environment}"
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)
  tags = {
    Owner = "devops"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name             = local.name
  cidr_block       = "10.0.0.0/16"
  azs              = local.azs
  public_subnets   = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets  = ["10.0.10.0/24", "10.0.11.0/24"]
  database_subnets = ["10.0.20.0/24", "10.0.21.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_flow_logs   = true

  tags = local.tags
}

# web tier
module "alb" {
  source = "../../modules/alb"

  name       = local.name
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids

  target_ids = { for k, m in module.web : k => m.instance_id }

  tags = local.tags
}

module "web_sg" {
  source = "../../modules/security-group"

  name        = "${local.name}-web"
  description = "Web servers - HTTP from the ALB only"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    http_from_alb = {
      from_port                    = 80
      referenced_security_group_id = module.alb.security_group_id
    }
  }

  tags = local.tags
}

module "web" {
  source   = "../../modules/ec2"
  for_each = { a = 0, b = 1 }

  name                   = "${local.name}-web-${each.key}"
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.private_subnet_ids[each.value]
  vpc_security_group_ids = [module.web_sg.security_group_id]

  iam_role_policy_arns = {
    assets_read = aws_iam_policy.assets_read.arn
  }

  user_data = <<-EOT
    #!/bin/bash
    dnf install -y nginx
    echo "Hello from $(hostname)" > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  EOT

  tags = local.tags
}

module "assets" {
  source = "../../modules/s3"

  bucket_prefix      = "${local.name}-assets-"
  versioning_enabled = true
  force_destroy      = true

  lifecycle_rules = [{
    id                                 = "cleanup"
    noncurrent_version_expiration_days = 30
    transitions = [
      { days = 90, storage_class = "STANDARD_IA" },
    ]
  }]

  tags = local.tags
}

data "aws_iam_policy_document" "assets_read" {
  statement {
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [module.assets.bucket_arn, "${module.assets.bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "assets_read" {
  name_prefix = "${local.name}-assets-read-"
  policy      = data.aws_iam_policy_document.assets_read.json
}

module "sessions" {
  source = "../../modules/dynamodb"

  name          = "${local.name}-sessions"
  hash_key      = "pk"
  range_key     = "sk"
  ttl_attribute = "expires_at"

  attributes = [
    { name = "pk", type = "S" },
    { name = "sk", type = "S" },
    { name = "user_id", type = "S" },
  ]

  global_secondary_indexes = [
    { name = "by-user", hash_key = "user_id", range_key = "sk" },
  ]

  deletion_protection = false

  tags = local.tags
}

module "db_sg" {
  source = "../../modules/security-group"

  name        = "${local.name}-db"
  description = "Postgres from web servers only"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    postgres_from_web = {
      from_port                    = 5432
      referenced_security_group_id = module.web_sg.security_group_id
    }
  }
  egress_rules = {}

  tags = local.tags
}

module "db" {
  source = "../../modules/rds"

  identifier             = "${local.name}-db"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t4g.micro"
  db_name                = "app"
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.db_sg.security_group_id]

  # fine for a demo, don't copy this into prod
  deletion_protection = false
  skip_final_snapshot = true

  tags = local.tags
}

module "ecr" {
  source = "../../modules/ecr"

  name         = "${local.name}/app"
  force_delete = true

  read_write_access_arns = var.github_repo != null ? [module.github_actions_role[0].role_arn] : []

  tags = local.tags
}

module "lambda" {
  source = "../../modules/lambda"

  function_name = "${local.name}-hello"
  source_dir    = "${path.module}/src"
  handler       = "index.handler"
  runtime       = "python3.12"

  environment_variables = {
    TABLE_NAME = module.sessions.table_name
  }

  inline_policy = data.aws_iam_policy_document.lambda_dynamodb.json

  tags = local.tags
}

data "aws_iam_policy_document" "lambda_dynamodb" {
  statement {
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query"]
    resources = [module.sessions.table_arn, "${module.sessions.table_arn}/index/*"]
  }
}

# lets github actions deploy without access keys
module "github_actions_role" {
  source = "../../modules/iam-role"
  count  = var.github_repo != null ? 1 : 0

  name        = "${local.name}-github-actions"
  description = "Assumed by GitHub Actions in ${var.github_repo}"

  create_github_oidc_provider = true # only one allowed per account
  github_oidc_subjects        = ["repo:${var.github_repo}:ref:refs/heads/main"]

  managed_policy_arns = {
    readonly = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  }

  tags = local.tags
}
