# ecs-fargate

One Fargate service with a single app container, plus its task definition, log group, execution and task roles, and security group. It creates a cluster unless you pass `cluster_arn`. Deployments use the circuit breaker, so a release that never gets healthy is rolled back automatically.

`desired_count` only applies at creation. After that it's ignored so autoscaling or a manual `aws ecs update-service --desired-count` doesn't get reverted on the next apply.

## Usage

```hcl
module "alb" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/alb?ref=v1.0.0"

  name        = "api-prod"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.public_subnet_ids
  target_type = "ip" # fargate tasks register by IP
  target_port = 8080
}

module "api" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/ecs-fargate?ref=v1.0.0"

  name       = "api-prod"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  cpu        = 512
  memory     = 1024

  container = {
    image = "${module.ecr.repository_url}:v1.4.2"
    port  = 8080
    environment = {
      TABLE_NAME = module.orders.table_name
    }
    secrets = {
      DB_PASSWORD = module.db.master_user_secret_arn
    }
  }

  ingress_security_group_ids = { alb = module.alb.security_group_id }
  target_group_arn           = module.alb.target_group_arn

  autoscaling = {
    min_capacity = 2
    max_capacity = 10
  }

  task_role_inline_policy = data.aws_iam_policy_document.api.json

  # the target group has to be on a listener before the service can use it
  depends_on = [module.alb]
}
```

Secrets go in as env var name => ARN (Secrets Manager or SSM parameter). The execution role gets read access to exactly those ARNs. A Secrets Manager ARN with a JSON key suffix (`arn:...:secret:db-AbCdEf:password::`) works too. If a secret is encrypted with a customer managed KMS key, add a decrypt policy through `execution_role_policy_arns`.

With `enable_execute_command = true` you can get a shell in a running task:

```bash
aws ecs execute-command --cluster api-prod --task <task-id> --container app --interactive --command /bin/sh
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name of the service. Also used for the task family, log group and (if created) the cluster | `string` | n/a | **yes** |
| `cluster_arn` | Existing ECS cluster ARN. Null creates a cluster named after the service | `string` | `null` | no |
| `container_insights` | Enable Container Insights on the cluster we create | `bool` | `true` | no |
| `vpc_id` | VPC ID for the service security group | `string` | n/a | **yes** |
| `subnet_ids` | Subnets for the tasks (usually private subnets with a NAT gateway) | `list(string)` | n/a | **yes** |
| `assign_public_ip` | Give tasks a public IP. Only needed in public subnets without NAT | `bool` | `false` | no |
| `ingress_security_group_ids` | Security groups allowed to reach the container port, keyed by a static name, e.g. { alb = module.alb.security_group_id } | `map(string)` | `{}` | no |
| `additional_security_group_ids` | Extra security groups to attach to the tasks | `list(string)` | `[]` | no |
| `container` | The app container. secrets maps env var name => Secrets Manager or SSM parameter ARN | `object` | n/a | **yes** |
| `cpu` | Task CPU units (256, 512, 1024, 2048, 4096, ...) | `number` | `256` | no |
| `memory` | Task memory in MiB, must be a valid combination with cpu | `number` | `512` | no |
| `cpu_architecture` | X86_64 or ARM64. ARM64 is cheaper but the image has to support it | `string` | `"X86_64"` | no |
| `desired_count` | Number of tasks at creation. Ignored afterwards so autoscaling and manual changes stick | `number` | `1` | no |
| `target_group_arn` | Target group to register tasks with (target_type must be ip). The target group must already be attached to a listener | `string` | `null` | no |
| `health_check_grace_period` | Seconds to ignore load balancer health checks after a task starts | `number` | `60` | no |
| `autoscaling` | Target tracking autoscaling. Null disables | `object` | `null` | no |
| `enable_execute_command` | Allow `aws ecs execute-command` into running tasks | `bool` | `false` | no |
| `wait_for_steady_state` | Wait for the service to reach a steady state on apply | `bool` | `false` | no |
| `task_role_policy_arns` | Managed policies for the task role (the app's permissions), keyed by a static name | `map(string)` | `{}` | no |
| `task_role_inline_policy` | Inline policy JSON for the task role | `string` | `null` | no |
| `execution_role_policy_arns` | Extra managed policies for the execution role, e.g. KMS decrypt for secrets on a customer key | `map(string)` | `{}` | no |
| `log_retention_days` | CloudWatch Logs retention in days | `number` | `30` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_arn` | ARN of the cluster the service runs in |
| `cluster_name` | Name of the cluster the service runs in |
| `service_name` | Name of the ECS service |
| `task_definition_arn` | ARN of the task definition (with revision) |
| `task_definition_family` | Task definition family |
| `security_group_id` | ID of the task security group. Allow this as a source on databases etc. |
| `task_role_arn` | ARN of the task role (the app's permissions) |
| `task_role_name` | Name of the task role |
| `execution_role_arn` | ARN of the task execution role |
| `log_group_name` | CloudWatch log group name |
<!-- END_TF_DOCS -->
