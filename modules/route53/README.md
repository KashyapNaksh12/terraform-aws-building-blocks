# route53

Route 53 hosted zone (public, or private when you pass VPCs) with records. Can also just manage records in a zone that already exists.

## Usage

New public zone:

```hcl
module "zone" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/route53?ref=v1.2.0"

  domain_name = "example.com"

  records = {
    apex = {
      name = "@"
      type = "A"
      alias = {
        name    = module.cdn.domain_name
        zone_id = module.cdn.hosted_zone_id
      }
    }
    mx = {
      name    = "@"
      type    = "MX"
      ttl     = 3600
      records = ["10 mail.example.com"]
    }
  }
}
```

Point the registrar at `name_servers` after the first apply.

Records in an existing zone:

```hcl
module "api_dns" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/route53?ref=v1.2.0"

  zone_id = "Z0123456789ABC"

  records = {
    api = {
      name = "api"
      type = "A"
      alias = {
        name    = module.alb.lb_dns_name
        zone_id = module.alb.lb_zone_id
      }
    }
  }
}
```

Private zone: set `vpc_ids`. Weighted or failover records need `set_identifier` plus `weight` or `failover` (PRIMARY / SECONDARY).

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `domain_name` | Zone name to create, e.g. example.com. Ignored when zone_id is set | `string` | `null` | no |
| `zone_id` | Existing zone to add records to. Null creates a new zone | `string` | `null` | no |
| `comment` | Zone comment | `string` | `"Managed by Terraform"` | no |
| `vpc_ids` | VPCs to associate, makes it a private zone. Empty creates a public zone | `list(string)` | `[]` | no |
| `delegation_set_id` | Reusable delegation set for the name servers (public zones only) | `string` | `null` | no |
| `force_destroy` | Delete all records (including ones not managed here) when destroying the zone | `bool` | `false` | no |
| `records` | Records keyed by a static name (name, type, ttl, records, alias, set_identifier, weight, failover, health_check_id, allow_overwrite) | `map(object)` | `{}` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `zone_id` | ID of the zone |
| `zone_arn` | ARN of the zone |
| `name_servers` | Name servers to set at the registrar (public zones) |
| `record_fqdns` | FQDNs keyed like var.records |
<!-- END_TF_DOCS -->
