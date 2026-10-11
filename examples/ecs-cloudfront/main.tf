data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name          = "${var.name}-${var.environment}"
  azs           = slice(data.aws_availability_zones.available.names, 0, 2)
  custom_domain = var.domain_name != null
  tags = {
    Owner = "devops"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name            = local.name
  cidr_block      = "10.1.0.0/16"
  azs             = local.azs
  public_subnets  = ["10.1.0.0/24", "10.1.1.0/24"]
  private_subnets = ["10.1.10.0/24", "10.1.11.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags
}

# only CloudFront can reach the ALB, nobody goes around the CDN
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

module "alb_from_cloudfront_sg" {
  source = "../../modules/security-group"

  name        = "${local.name}-alb-cf"
  description = "HTTP from CloudFront origin-facing IPs"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    http_from_cloudfront = {
      from_port      = 80
      prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront.id
    }
  }
  egress_rules = {}

  tags = local.tags
}

module "alb" {
  source = "../../modules/alb"

  name       = local.name
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids

  allowed_cidrs                 = []
  additional_security_group_ids = [module.alb_from_cloudfront_sg.security_group_id]

  target_type = "ip"
  target_port = 80

  tags = local.tags
}

module "app" {
  source = "../../modules/ecs-fargate"

  name       = local.name
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  container = {
    image = var.image
    port  = 80
    environment = {
      ENVIRONMENT = var.environment
    }
  }

  ingress_security_group_ids = { alb = module.alb.security_group_id }
  target_group_arn           = module.alb.target_group_arn

  autoscaling = {
    min_capacity = 1
    max_capacity = 3
  }

  enable_execute_command = true

  tags = local.tags

  # the target group has to be on a listener before the service can use it
  depends_on = [module.alb]
}

module "cert" {
  source = "../../modules/acm"
  count  = local.custom_domain ? 1 : 0

  providers = {
    aws = aws.us_east_1
  }

  domain_name     = var.domain_name
  route53_zone_id = var.route53_zone_id

  tags = local.tags
}

module "cdn" {
  source = "../../modules/cloudfront"

  name               = local.name
  origin_type        = "custom"
  origin_domain_name = module.alb.lb_dns_name

  # the ALB only has its amazonaws.com name here, which no cert covers. with
  # your own domain on the ALB too, switch to https-only
  custom_origin_config = {
    origin_protocol_policy = "http-only"
  }

  aliases             = local.custom_domain ? [var.domain_name] : []
  acm_certificate_arn = local.custom_domain ? module.cert[0].certificate_arn : null

  tags = local.tags
}

resource "aws_route53_record" "app" {
  for_each = local.custom_domain ? toset(["A", "AAAA"]) : toset([])

  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = each.key

  alias {
    name                   = module.cdn.domain_name
    zone_id                = module.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
