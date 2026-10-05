# lambda

Lambda function plus its execution role and log group. Code can come from a local folder (zipped for you), a zip file, S3 or a container image.

## Usage

```hcl
module "worker" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/lambda?ref=v1.0.0"

  function_name = "order-worker"
  source_dir    = "${path.module}/src/worker"
  handler       = "main.handler"
  runtime       = "python3.12"
  memory_size   = 256
  timeout       = 30

  environment_variables = {
    TABLE_NAME = module.orders.table_name
  }

  inline_policy = data.aws_iam_policy_document.worker.json

  # only if it needs to reach things inside the VPC
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.worker_sg.security_group_id]
}
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `function_name` | Name of the Lambda function | `string` | n/a | **yes** |
| `description` | Description of the function | `string` | `"Managed by Terraform"` | no |
| `source_dir` | Local folder to zip up. Use one of source_dir, filename, image_uri or s3_bucket | `string` | `null` | no |
| `filename` | Path to a pre-built deployment zip | `string` | `null` | no |
| `s3_bucket` | S3 bucket holding the deployment zip (with s3_key) | `string` | `null` | no |
| `s3_key` | S3 key of the deployment zip | `string` | `null` | no |
| `image_uri` | ECR image URI for container-image functions | `string` | `null` | no |
| `handler` | Function entrypoint (ignored for container images) | `string` | `"index.handler"` | no |
| `runtime` | Runtime identifier (ignored for container images) | `string` | `"python3.12"` | no |
| `architectures` | Instruction set: ["x86_64"] or ["arm64"] | `list(string)` | `["arm64"]` | no |
| `memory_size` | Memory in MB | `number` | `128` | no |
| `timeout` | Timeout in seconds | `number` | `10` | no |
| `reserved_concurrent_executions` | Reserved concurrency. -1 means unreserved | `number` | `-1` | no |
| `environment_variables` | Environment variables for the function | `map(string)` | `{}` | no |
| `subnet_ids` | Subnets for VPC-attached functions. Empty means no VPC | `list(string)` | `[]` | no |
| `security_group_ids` | Security groups for VPC-attached functions | `list(string)` | `[]` | no |
| `policy_arns` | Extra managed policy ARNs for the execution role, keyed by a static name | `map(string)` | `{}` | no |
| `inline_policy` | Inline policy JSON to attach to the execution role | `string` | `null` | no |
| `log_retention_days` | CloudWatch Logs retention in days | `number` | `30` | no |
| `tracing_mode` | X-Ray tracing mode: PassThrough or Active. Null disables | `string` | `null` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `function_name` | Name of the function |
| `function_arn` | ARN of the function |
| `invoke_arn` | Invoke ARN (for API Gateway integrations) |
| `qualified_arn` | ARN including the latest published version |
| `role_name` | Name of the execution role |
| `role_arn` | ARN of the execution role |
| `log_group_name` | CloudWatch log group name |
<!-- END_TF_DOCS -->
