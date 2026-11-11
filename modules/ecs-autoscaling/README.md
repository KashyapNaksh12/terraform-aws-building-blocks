# ecs-autoscaling

Target tracking autoscaling for an ECS service: a scalable target plus a CPU policy and an optional memory policy. Used by [ecs-fargate](../ecs-fargate).

The service should ignore changes to `desired_count`, otherwise Terraform resets the task count on every apply.

## Usage

```hcl
module "autoscaling" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/ecs-autoscaling?ref=v1.4.0"

  name          = "api"
  cluster_name  = "prod"
  service_name  = aws_ecs_service.api.name
  min_capacity  = 2
  max_capacity  = 10
  cpu_target    = 60
  memory_target = 75
}
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name prefix for the scaling policies, usually the service name | `string` | n/a | **yes** |
| `cluster_name` | Name of the ECS cluster the service runs in | `string` | n/a | **yes** |
| `service_name` | Name of the ECS service to scale | `string` | n/a | **yes** |
| `min_capacity` | Minimum number of tasks | `number` | n/a | **yes** |
| `max_capacity` | Maximum number of tasks | `number` | n/a | **yes** |
| `cpu_target` | Target average CPU utilization in percent | `number` | `70` | no |
| `memory_target` | Target average memory utilization in percent. Null skips the memory policy | `number` | `null` | no |
| `scale_in_cooldown` | Seconds to wait after a scale in before scaling in again | `number` | `300` | no |
| `scale_out_cooldown` | Seconds to wait after a scale out before scaling out again | `number` | `60` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `target_resource_id` | Resource ID of the scalable target (service/<cluster>/<service>) |
| `cpu_policy_arn` | ARN of the CPU target tracking policy |
| `memory_policy_arn` | ARN of the memory target tracking policy, null when memory_target is not set |
<!-- END_TF_DOCS -->
