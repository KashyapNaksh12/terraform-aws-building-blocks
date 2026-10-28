# efs

Encrypted EFS file system with mount targets, access points, lifecycle to IA, AWS Backup and a policy that requires TLS and mounting through a mount target.

## Usage

Shared storage for a Fargate service:

```hcl
module "efs" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/efs?ref=v1.2.0"

  name        = "prod-uploads"
  kms_key_arn = module.kms.key_arn

  mount_target_subnet_ids = {
    a = module.vpc.private_subnet_ids[0]
    b = module.vpc.private_subnet_ids[1]
  }
  security_group_ids = [module.efs_sg.security_group_id] # NFS 2049 from the app SG

  access_points = {
    app = {
      path = "/app"
      uid  = 1000
      gid  = 1000
    }
  }
}
```

In the ECS task definition use `transit_encryption = "ENABLED"` and the access point ID from `access_point_ids["app"]`. On EC2 mount with the EFS mount helper and `-o tls`, plain NFS without TLS is denied by the policy.

Mount targets are keyed by a static name rather than a list, so subnet IDs that are only known after apply don't break `for_each`. Use one subnet per AZ.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name of the file system, also the creation token | `string` | n/a | yes |
| `kms_key_arn` | KMS key for encryption at rest. Null uses the AWS-managed aws/elasticfilesystem key | `string` | `null` | no |
| `performance_mode` | generalPurpose or maxIO | `string` | `"generalPurpose"` | no |
| `throughput_mode` | elastic, bursting or provisioned | `string` | `"elastic"` | no |
| `provisioned_throughput_in_mibps` | Throughput when throughput_mode is provisioned | `number` | `null` | no |
| `transition_to_ia` | Move files to Infrequent Access after this, e.g. AFTER_30_DAYS. Null turns it off | `string` | `"AFTER_30_DAYS"` | no |
| `transition_to_archive` | Move files to Archive after this, e.g. AFTER_90_DAYS (elastic throughput only). Null turns it off | `string` | `null` | no |
| `transition_to_primary_storage_class` | Move files back to Standard on access, AFTER_1_ACCESS. Null turns it off | `string` | `"AFTER_1_ACCESS"` | no |
| `enable_backup` | Turn on AWS Backup for the file system | `bool` | `true` | no |
| `replication_overwrite_protection` | Stop the file system being used as a replication destination | `bool` | `true` | no |
| `mount_target_subnet_ids` | Subnets for mount targets, one per AZ, keyed by a static name | `map(string)` | `{}` | no |
| `security_group_ids` | Security groups for the mount targets (allow NFS 2049 from clients) | `list(string)` | `[]` | no |
| `access_points` | Access points keyed by a static name (path, uid, gid, secondary_gids, permissions) | `map(object)` | `{}` | no |
| `policy` | Extra file system policy JSON, merged with the generated statements | `string` | `null` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `file_system_id` | ID of the file system |
| `file_system_arn` | ARN of the file system |
| `dns_name` | DNS name for mounting |
| `mount_target_ids` | Mount target IDs keyed like var.mount_target_subnet_ids |
| `access_point_ids` | Access point IDs keyed like var.access_points |
| `access_point_arns` | Access point ARNs keyed like var.access_points |
<!-- END_TF_DOCS -->
