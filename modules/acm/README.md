# acm

ACM certificate validated through DNS. Give it a Route 53 zone and it creates the validation records and waits until the cert is issued. Without a zone, add the records from the `validation_records` output to your DNS yourself.

## Usage

```hcl
module "cert" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/acm?ref=v1.0.0"

  domain_name               = "example.com"
  subject_alternative_names = ["*.example.com"]
  route53_zone_id           = aws_route53_zone.main.zone_id
}
```

For CloudFront the certificate has to live in us-east-1, so pass an aliased provider:

```hcl
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "cdn_cert" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/acm?ref=v1.0.0"

  providers = {
    aws = aws.us_east_1
  }

  domain_name     = "app.example.com"
  route53_zone_id = aws_route53_zone.main.zone_id
}
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `domain_name` | Main domain for the certificate, e.g. example.com or *.example.com | `string` | n/a | **yes** |
| `subject_alternative_names` | Extra domains on the same certificate | `list(string)` | `[]` | no |
| `key_algorithm` | Key algorithm: RSA_2048, EC_prime256v1 or EC_secp384r1 | `string` | `"RSA_2048"` | no |
| `route53_zone_id` | Route 53 zone to create the validation records in. Null means you add them yourself (see validation_records output) | `string` | `null` | no |
| `wait_for_validation` | Wait until the certificate is issued (only with route53_zone_id) | `bool` | `true` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `certificate_arn` | ARN of the certificate. When validated through Route 53 this only resolves once it's issued |
| `certificate_domain_name` | Main domain of the certificate |
| `validation_records` | DNS records that prove domain ownership. Add these yourself if not using route53_zone_id |
<!-- END_TF_DOCS -->
