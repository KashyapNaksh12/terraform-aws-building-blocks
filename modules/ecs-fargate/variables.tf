variable "name" {
  description = "Name of the service. Also used for the task family, log group and (if created) the cluster"
  type        = string
}

variable "cluster_arn" {
  description = "Existing ECS cluster ARN. Null creates a cluster named after the service"
  type        = string
  default     = null
}

variable "container_insights" {
  description = "Enable Container Insights on the cluster we create"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID for the service security group"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the tasks (usually private subnets with a NAT gateway)"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Give tasks a public IP. Only needed in public subnets without NAT"
  type        = bool
  default     = false
}

variable "ingress_security_group_ids" {
  description = "Security groups allowed to reach the container port, keyed by a static name, e.g. { alb = module.alb.security_group_id }"
  type        = map(string)
  default     = {}
}

variable "additional_security_group_ids" {
  description = "Extra security groups to attach to the tasks"
  type        = list(string)
  default     = []
}

variable "container" {
  description = "The app container. secrets maps env var name => Secrets Manager or SSM parameter ARN"
  type = object({
    name                     = optional(string, "app")
    image                    = string
    port                     = optional(number)
    command                  = optional(list(string))
    environment              = optional(map(string), {})
    secrets                  = optional(map(string), {})
    health_check_command     = optional(list(string))
    readonly_root_filesystem = optional(bool, false)
  })
}

variable "cpu" {
  description = "Task CPU units (256, 512, 1024, 2048, 4096, ...)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Task memory in MiB, must be a valid combination with cpu"
  type        = number
  default     = 512
}

variable "cpu_architecture" {
  description = "X86_64 or ARM64. ARM64 is cheaper but the image has to support it"
  type        = string
  default     = "X86_64"
}

variable "desired_count" {
  description = "Number of tasks at creation. Ignored afterwards so autoscaling and manual changes stick"
  type        = number
  default     = 1
}

variable "target_group_arn" {
  description = "Target group to register tasks with (target_type must be ip). The target group must already be attached to a listener"
  type        = string
  default     = null
}

variable "health_check_grace_period" {
  description = "Seconds to ignore load balancer health checks after a task starts"
  type        = number
  default     = 60
}

variable "autoscaling" {
  description = "Target tracking autoscaling. Null disables"
  type = object({
    min_capacity  = number
    max_capacity  = number
    cpu_target    = optional(number, 70)
    memory_target = optional(number)
  })
  default = null
}

variable "enable_execute_command" {
  description = "Allow `aws ecs execute-command` into running tasks"
  type        = bool
  default     = false
}

variable "wait_for_steady_state" {
  description = "Wait for the service to reach a steady state on apply"
  type        = bool
  default     = false
}

variable "task_role_policy_arns" {
  description = "Managed policies for the task role (the app's permissions), keyed by a static name"
  type        = map(string)
  default     = {}
}

variable "task_role_inline_policy" {
  description = "Inline policy JSON for the task role"
  type        = string
  default     = null
}

variable "execution_role_policy_arns" {
  description = "Extra managed policies for the execution role, e.g. KMS decrypt for secrets on a customer key"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
