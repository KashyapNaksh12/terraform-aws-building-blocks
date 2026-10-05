# s3

S3 bucket with public access blocked, ACLs disabled, versioning and encryption on, and a policy that denies plain HTTP. Lifecycle rules, CORS and access logging are optional. Anything you pass in `policy` gets merged with the TLS statement.

## Usage

```hcl
module "assets" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/s3?ref=v1.0.0"

  bucket_name = "my-company-assets-prod"
  kms_key_arn = aws_kms_key.s3.arn

  lifecycle_rules = [{
    id                                 = "archive"
    noncurrent_version_expiration_days = 90
    transitions = [
      { days = 30, storage_class = "STANDARD_IA" },
      { days = 180, storage_class = "GLACIER" },
    ]
  }]
}
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `bucket_name` | Globally unique bucket name. Mutually exclusive with bucket_prefix | `string` | `null` | no |
| `bucket_prefix` | Prefix for a generated unique bucket name. Used when bucket_name is null | `string` | `null` | no |
| `force_destroy` | Allow Terraform to delete the bucket even if it contains objects | `bool` | `false` | no |
| `versioning_enabled` | Enable object versioning | `bool` | `true` | no |
| `kms_key_arn` | KMS key ARN for SSE-KMS. Null uses SSE-S3 (AES256) | `string` | `null` | no |
| `block_public_access` | Enable all four S3 Block Public Access settings | `bool` | `true` | no |
| `object_ownership` | BucketOwnerEnforced (ACLs off), BucketOwnerPreferred or ObjectWriter | `string` | `"BucketOwnerEnforced"` | no |
| `enforce_tls` | Add a bucket policy statement denying non-TLS requests | `bool` | `true` | no |
| `policy` | Additional bucket policy JSON to merge with the module's generated statements | `string` | `null` | no |
| `lifecycle_rules` | Lifecycle rules (transitions, expiry, old version cleanup) | `list(object)` | `[]` | no |
| `cors_rules` | CORS rules for the bucket | `list(object)` | `[]` | no |
| `logging_target_bucket` | Bucket to send server access logs to. Null disables access logging | `string` | `null` | no |
| `logging_target_prefix` | Prefix for access log objects | `string` | `"access-logs/"` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_id` | Name (ID) of the bucket |
| `bucket_arn` | ARN of the bucket |
| `bucket_domain_name` | Bucket domain name (bucket.s3.amazonaws.com) |
| `bucket_regional_domain_name` | Region-specific bucket domain name (use for CloudFront origins) |
<!-- END_TF_DOCS -->
