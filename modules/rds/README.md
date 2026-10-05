# rds

RDS instance for postgres, mysql or mariadb. The master password is handled by RDS and stored in Secrets Manager (`manage_master_user_password`), so it never ends up in the state file. Backups and deletion protection are on by default.

## Usage

```hcl
module "db" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/rds?ref=v1.0.0"

  identifier             = "app-prod"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.r6g.large"
  db_name                = "app"
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.db_sg.security_group_id]
  multi_az               = true

  performance_insights_enabled    = true
  monitoring_interval             = 60
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  parameter_group_family = "postgres16"
  parameters = [
    { name = "log_min_duration_statement", value = "500", apply_method = "immediate" },
  ]
}
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `identifier` | Unique identifier for the DB instance | `string` | n/a | **yes** |
| `engine` | Database engine: postgres, mysql, mariadb | `string` | `"postgres"` | no |
| `engine_version` | Engine version (e.g. 16.4 for postgres, 8.0 for mysql) | `string` | `"16"` | no |
| `instance_class` | DB instance class | `string` | `"db.t4g.micro"` | no |
| `allocated_storage` | Initial allocated storage in GiB | `number` | `20` | no |
| `max_allocated_storage` | Upper limit for storage autoscaling in GiB. Set to 0 to disable autoscaling | `number` | `100` | no |
| `storage_type` | Storage type: gp3, gp2, io1, io2 | `string` | `"gp3"` | no |
| `kms_key_id` | KMS key ARN for storage encryption. Null uses the AWS-managed RDS key | `string` | `null` | no |
| `db_name` | Name of the initial database to create | `string` | `null` | no |
| `username` | Master username | `string` | `"dbadmin"` | no |
| `port` | Port to listen on. Null uses the engine default | `number` | `null` | no |
| `db_subnet_group_name` | Name of an existing DB subnet group. If null, one is created from subnet_ids | `string` | `null` | no |
| `subnet_ids` | Subnet IDs for a new DB subnet group (used when db_subnet_group_name is null) | `list(string)` | `[]` | no |
| `vpc_security_group_ids` | Security group IDs to attach to the instance | `list(string)` | `[]` | no |
| `multi_az` | Deploy a standby in another AZ | `bool` | `false` | no |
| `publicly_accessible` | Give the instance a public endpoint. Keep false for production | `bool` | `false` | no |
| `backup_retention_period` | Days to retain automated backups (0 disables) | `number` | `7` | no |
| `backup_window` | Daily backup window (UTC), e.g. 03:00-04:00 | `string` | `"03:00-04:00"` | no |
| `maintenance_window` | Weekly maintenance window (UTC), e.g. sun:04:30-sun:05:30 | `string` | `"sun:04:30-sun:05:30"` | no |
| `deletion_protection` | Prevent the instance from being deleted | `bool` | `true` | no |
| `skip_final_snapshot` | Skip the final snapshot on deletion | `bool` | `false` | no |
| `apply_immediately` | Apply modifications immediately instead of in the maintenance window | `bool` | `false` | no |
| `auto_minor_version_upgrade` | Automatically apply minor engine upgrades | `bool` | `true` | no |
| `performance_insights_enabled` | Enable Performance Insights | `bool` | `false` | no |
| `monitoring_interval` | Enhanced Monitoring interval in seconds (0, 1, 5, 10, 15, 30, 60). 0 disables | `number` | `0` | no |
| `enabled_cloudwatch_logs_exports` | Log types to export to CloudWatch (e.g. ["postgresql", "upgrade"]) | `list(string)` | `[]` | no |
| `parameter_group_family` | Parameter group family, e.g. postgres16. Leave null to use the default group | `string` | `null` | no |
| `parameters` | DB parameters for the custom parameter group | `list(object)` | `[]` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `db_instance_id` | Identifier of the DB instance |
| `db_instance_arn` | ARN of the DB instance |
| `endpoint` | Connection endpoint (host:port) |
| `address` | Hostname of the DB instance |
| `port` | Port the DB instance listens on |
| `db_name` | Name of the initial database |
| `master_username` | Master username |
| `master_user_secret_arn` | ARN of the Secrets Manager secret holding the master password |
<!-- END_TF_DOCS -->
