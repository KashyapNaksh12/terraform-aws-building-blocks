# elasticache

Valkey or Redis replication group. Encryption at rest and in transit is always on, automatic failover and Multi-AZ turn on when there are replicas, and the slow log goes to CloudWatch.

## Usage

```hcl
module "cache" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/elasticache?ref=v1.2.0"

  name               = "prod-cache"
  node_type          = "cache.t4g.small"
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.cache_sg.security_group_id] # 6379 from the app SG
  kms_key_arn        = module.kms.key_arn
}
```

Clients have to connect with TLS (`rediss://`). Connect to `primary_endpoint_address` for writes and `reader_endpoint_address` for reads. With `cluster_mode_enabled` use `configuration_endpoint_address` and a cluster-aware client.

`replicas_per_node_group = 0` gives a single node with no failover, fine for dev.

For auth, prefer RBAC with `user_group_ids`. `auth_token` works but ends up in state.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Replication group ID, also used for the subnet/parameter group and log group (max 40 chars) | `string` | n/a | yes |
| `description` | Description of the replication group | `string` | `"Managed by Terraform"` | no |
| `engine` | redis or valkey | `string` | `"valkey"` | no |
| `engine_version` | Engine version, e.g. 8.0 for valkey or 7.1 for redis | `string` | `"8.0"` | no |
| `node_type` | Node type | `string` | `"cache.t4g.micro"` | no |
| `port` | Port | `number` | `6379` | no |
| `parameter_group_family` | Family for a new parameter group, e.g. valkey8 or redis7. Null skips it | `string` | `null` | no |
| `parameters` | Parameters for the new parameter group, name => value | `map(string)` | `{}` | no |
| `parameter_group_name` | Existing parameter group (used when parameter_group_family is null). Null uses the engine default | `string` | `null` | no |
| `cluster_mode_enabled` | Shard data across num_node_groups | `bool` | `false` | no |
| `num_node_groups` | Number of shards (cluster mode only) | `number` | `1` | no |
| `replicas_per_node_group` | Replicas per shard (0-5). At least 1 turns on automatic failover | `number` | `1` | no |
| `multi_az_enabled` | Fail over across AZs. Only applies when there are replicas | `bool` | `true` | no |
| `subnet_group_name` | Existing subnet group. Null creates one from subnet_ids | `string` | `null` | no |
| `subnet_ids` | Subnet IDs for a new subnet group | `list(string)` | `[]` | no |
| `security_group_ids` | Security groups for the nodes | `list(string)` | `[]` | no |
| `kms_key_arn` | KMS key for encryption at rest. Null uses the AWS-managed key | `string` | `null` | no |
| `auth_token` | AUTH token (16-128 chars). Ends up in state, prefer user_group_ids for RBAC | `string` | `null` | no |
| `user_group_ids` | RBAC user group IDs (max 1) | `list(string)` | `[]` | no |
| `snapshot_retention_limit` | Days to keep automatic snapshots, 0 turns them off | `number` | `7` | no |
| `snapshot_window` | Daily snapshot window (UTC), e.g. 03:00-04:00 | `string` | `"03:00-04:00"` | no |
| `maintenance_window` | Weekly maintenance window (UTC), e.g. sun:05:00-sun:06:00 | `string` | `"sun:05:00-sun:06:00"` | no |
| `skip_final_snapshot` | Skip the final snapshot on delete | `bool` | `false` | no |
| `apply_immediately` | Apply changes now instead of in the maintenance window | `bool` | `false` | no |
| `auto_minor_version_upgrade` | Upgrade minor versions in the maintenance window | `bool` | `true` | no |
| `notification_topic_arn` | SNS topic for ElastiCache events | `string` | `null` | no |
| `enable_slow_log` | Send the slow log to CloudWatch Logs | `bool` | `true` | no |
| `log_retention_days` | Retention for the slow log group | `number` | `30` | no |
| `log_kms_key_arn` | KMS key for the slow log group (key policy must allow CloudWatch Logs) | `string` | `null` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `replication_group_id` | ID of the replication group |
| `replication_group_arn` | ARN of the replication group |
| `primary_endpoint_address` | Primary endpoint (cluster mode disabled) |
| `reader_endpoint_address` | Reader endpoint (cluster mode disabled) |
| `configuration_endpoint_address` | Configuration endpoint (cluster mode enabled) |
| `port` | Port |
<!-- END_TF_DOCS -->
