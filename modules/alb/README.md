# alb

Application load balancer with its own security group and one target group. Without a certificate you get a plain HTTP listener. Pass `certificate_arn` and it adds HTTPS and redirects port 80.

## Usage

```hcl
module "alb" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/alb?ref=v1.0.0"

  name            = "app-prod"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnet_ids
  certificate_arn = aws_acm_certificate.app.arn

  target_port = 8080
  health_check = {
    path = "/healthz"
  }

  target_ids = {
    web1 = module.web1.instance_id
    web2 = module.web2.instance_id
  }
}

# on the targets' SG you'll want something like:
#   ingress_rules = { from_alb = { from_port = 8080, referenced_security_group_id = module.alb.security_group_id } }
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name of the load balancer (max 32 chars) | `string` | n/a | **yes** |
| `vpc_id` | VPC ID for the target group and security group | `string` | n/a | **yes** |
| `subnet_ids` | Subnets for the ALB (public subnets for internet-facing, at least two AZs) | `list(string)` | n/a | **yes** |
| `internal` | Create an internal (private) load balancer | `bool` | `false` | no |
| `allowed_cidrs` | IPv4 CIDRs allowed to reach the ALB listeners | `list(string)` | `["0.0.0.0/0"]` | no |
| `additional_security_group_ids` | Extra security groups to attach to the ALB | `list(string)` | `[]` | no |
| `certificate_arn` | ACM cert ARN. If set we add a 443 listener and redirect 80 to it | `string` | `null` | no |
| `ssl_policy` | SSL policy for the HTTPS listener | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | no |
| `target_type` | Target type: instance, ip, or lambda | `string` | `"instance"` | no |
| `target_port` | Port targets receive traffic on | `number` | `80` | no |
| `target_protocol` | Protocol used to reach targets: HTTP or HTTPS | `string` | `"HTTP"` | no |
| `health_check` | Target group health check settings | `object` | `{}` | no |
| `target_ids` | Targets to register (instance IDs or IPs), keyed by a static name | `map(string)` | `{}` | no |
| `idle_timeout` | Idle timeout in seconds | `number` | `60` | no |
| `enable_deletion_protection` | Enable deletion protection on the ALB | `bool` | `false` | no |
| `access_logs_bucket` | S3 bucket for ALB access logs. Null disables access logs | `string` | `null` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `lb_arn` | ARN of the load balancer |
| `lb_dns_name` | DNS name of the load balancer |
| `lb_zone_id` | Hosted zone ID of the load balancer (for Route 53 alias records) |
| `security_group_id` | ID of the ALB security group. Allow this as a source on your targets' security group |
| `target_group_arn` | ARN of the default target group |
| `http_listener_arn` | ARN of the HTTP listener |
| `https_listener_arn` | ARN of the HTTPS listener (null if no certificate) |
<!-- END_TF_DOCS -->
