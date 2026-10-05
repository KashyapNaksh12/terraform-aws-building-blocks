# security-group

Security group where rules are passed as maps. Uses the newer `aws_vpc_security_group_ingress_rule` / `egress_rule` resources so changing one rule doesn't touch the others.

## Usage

```hcl
module "app_sg" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/security-group?ref=v1.0.0"

  name   = "app"
  vpc_id = module.vpc.vpc_id

  ingress_rules = {
    https_public = { from_port = 443, cidr_ipv4 = "0.0.0.0/0" }
    app_from_alb = { from_port = 8080, referenced_security_group_id = module.alb.security_group_id }
    all_from_vpc = { ip_protocol = "-1", cidr_ipv4 = "10.0.0.0/16" }
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name of the security group | `string` | n/a | **yes** |
| `description` | Description of the security group | `string` | `"Managed by Terraform"` | no |
| `vpc_id` | ID of the VPC to create the security group in | `string` | n/a | **yes** |
| `ingress_rules` | Ingress rules keyed by name. Give each one a single source (cidr_ipv4, cidr_ipv6, prefix_list_id or referenced_security_group_id) | `map(object)` | `{}` | no |
| `egress_rules` | Egress rules, same format as ingress_rules. Default allows all outbound | `map(object)` | `{...}` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `security_group_id` | ID of the security group |
| `security_group_arn` | ARN of the security group |
| `security_group_name` | Generated name of the security group |
<!-- END_TF_DOCS -->
