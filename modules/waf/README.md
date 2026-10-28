# waf

WAFv2 web ACL with AWS managed rule groups, an IP block list, a per-IP rate limit and logging to CloudWatch Logs. Works for regional resources (ALB, API Gateway) and CloudFront.

## Usage

In front of an ALB:

```hcl
module "waf" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/waf?ref=v1.2.0"

  name          = "prod-alb"
  resource_arns = { alb = module.alb.lb_arn }
  rate_limit    = 1000
}
```

For CloudFront, the ACL has to be created in us-east-1 and attached on the distribution:

```hcl
module "waf_cdn" {
  source    = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/waf?ref=v1.2.0"
  providers = { aws = aws.us_east_1 }

  name  = "prod-cdn"
  scope = "CLOUDFRONT"
}

# then web_acl_id = module.waf_cdn.web_acl_arn on the distribution
```

By default you get the Common, Known Bad Inputs and IP Reputation groups, a 2000 requests / 5 min per-IP limit, and logs with the `authorization` and `cookie` headers redacted.

If the common rule set blocks legitimate requests (large uploads hit `SizeRestrictions_BODY`), switch single rules to count:

```hcl
managed_rule_groups = {
  common = {
    name           = "AWSManagedRulesCommonRuleSet"
    priority       = 1
    excluded_rules = ["SizeRestrictions_BODY"]
  }
}
```

Or set `count_only = true` on a group to watch what it would block before turning it on. Managed groups take the lowest priorities, then the IP block list, then the rate limit.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name of the web ACL, also used for metrics and the log group | `string` | n/a | yes |
| `description` | Description of the web ACL | `string` | `"Managed by Terraform"` | no |
| `scope` | REGIONAL (ALB, API Gateway) or CLOUDFRONT. CLOUDFRONT needs a provider in us-east-1 | `string` | `"REGIONAL"` | no |
| `default_action` | allow or block requests that don't match a rule | `string` | `"allow"` | no |
| `managed_rule_groups` | Managed rule groups keyed by rule name (name, priority, vendor_name, version, count_only, excluded_rules) | `map(object)` | Common, KnownBadInputs, IpReputation | no |
| `blocked_ip_cidrs` | IPv4 CIDRs to always block | `list(string)` | `[]` | no |
| `rate_limit` | Max requests per IP in rate_limit_window_sec before blocking. Null turns it off | `number` | `2000` | no |
| `rate_limit_window_sec` | Rate limit window, 60, 120, 300 or 600 seconds | `number` | `300` | no |
| `resource_arns` | Regional resources (ALB, API Gateway stage) to protect, keyed by a static name. Ignored for CLOUDFRONT | `map(string)` | `{}` | no |
| `enable_logging` | Send WAF logs to CloudWatch Logs | `bool` | `true` | no |
| `log_retention_days` | Retention for the log group | `number` | `30` | no |
| `log_kms_key_arn` | KMS key for the log group (key policy must allow CloudWatch Logs) | `string` | `null` | no |
| `redacted_headers` | Headers to keep out of the logs, lowercase | `list(string)` | `["authorization", "cookie"]` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `web_acl_id` | ID of the web ACL |
| `web_acl_arn` | ARN of the web ACL, pass it as web_acl_id to CloudFront |
| `web_acl_name` | Name of the web ACL |
| `log_group_name` | Log group for WAF logs (null if logging is off) |
<!-- END_TF_DOCS -->
