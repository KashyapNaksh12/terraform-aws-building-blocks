# log-bucket

Private, versioned, encrypted S3 bucket for logs and audit data. Used by the [cloudtrail](../cloudtrail) and [config](../config) modules, and handy for anything else that needs a bucket nobody can read over HTTP or make public.

## Usage

```hcl
data "aws_iam_policy_document" "writer" {
  statement {
    sid       = "ServiceWrite"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::my-logs/AWSLogs/*"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
}

module "log_bucket" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/log-bucket?ref=v1.5.0"

  bucket_name             = "my-logs"
  kms_key_arn             = module.kms.key_arn
  retention_days          = 365
  glacier_transition_days = 90

  source_policy_documents = [data.aws_iam_policy_document.writer.json]
}
```

What you get:

- `BucketOwnerEnforced` ownership, Block Public Access, versioning
- SSE with your KMS key (bucket key on), or AES256 when none is given
- A lifecycle rule for Glacier, expiry, old versions and unfinished uploads
- A bucket policy that denies non-TLS requests, plus whatever you pass in `source_policy_documents`. `deny_object_deletion = true` also denies manual deletes
- Optional Object Lock (`object_lock`) and server access logging (`access_logging_bucket`)

Build the ARN in your policy document from the bucket name, not from this module's output, or the policy will depend on the bucket it is attached to.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `bucket_name` | Name of the bucket | `string` | n/a | **yes** |
| `force_destroy` | Let Terraform delete the bucket with objects in it | `bool` | `false` | no |
| `kms_key_arn` | KMS key for default encryption. Null uses SSE-S3 (AES256) | `string` | `null` | no |
| `object_lock` | Turn on S3 Object Lock with a default retention (mode GOVERNANCE or COMPLIANCE). Can only be set when the bucket is created | `object({ mode = optional(string, "GOVERNANCE"), days = number })` | `null` | no |
| `lifecycle_rule_id` | ID of the lifecycle rule | `string` | `"retention"` | no |
| `glacier_transition_days` | Move objects to Glacier after this many days. Null keeps them in Standard | `number` | `null` | no |
| `retention_days` | Delete objects after this many days. Null keeps them forever | `number` | `null` | no |
| `noncurrent_version_retention_days` | Delete noncurrent object versions after this many days | `number` | `30` | no |
| `access_logging_bucket` | Bucket for S3 server access logs of this bucket. Null turns access logging off | `string` | `null` | no |
| `deny_object_deletion` | Bucket policy denies deleting objects and versions for everyone. Lifecycle expiry is not affected. Needs force_destroy = false | `bool` | `false` | no |
| `source_policy_documents` | IAM policy documents (JSON) merged into the bucket policy, e.g. the statements that let a service write to the bucket. Sids must not clash with DenyInsecureTransport and DenyObjectDeletion | `list(string)` | `[]` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_name` | Name of the bucket |
| `bucket_arn` | ARN of the bucket |
<!-- END_TF_DOCS -->
