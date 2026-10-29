variable "name_prefix" {
  description = "Prefix for alarm names, e.g. prod"
  type        = string
}

variable "alarm_actions" {
  description = "ARNs to notify when an alarm fires, usually an SNS topic"
  type        = list(string)
  default     = []
}

variable "send_ok" {
  description = "Also notify alarm_actions when an alarm goes back to OK"
  type        = bool
  default     = true
}

variable "rds" {
  description = "RDS instances to watch, keyed by a static name: CPU, free storage and freeable memory"
  type = map(object({
    instance_id        = string
    cpu_threshold      = optional(number, 80)
    free_storage_gb    = optional(number, 5)
    freeable_memory_mb = optional(number, 256)
  }))
  default = {}
}

variable "alb" {
  description = "ALBs to watch, keyed by a static name: ELB and target 5xx, p95 response time, and unhealthy hosts when target_group_arn is set"
  type = map(object({
    lb_arn                = string
    target_group_arn      = optional(string)
    elb_5xx_threshold     = optional(number, 10)
    target_5xx_threshold  = optional(number, 10)
    response_time_seconds = optional(number, 1)
  }))
  default = {}
}

variable "ecs" {
  description = "ECS services to watch, keyed by a static name: CPU and memory"
  type = map(object({
    cluster_name     = string
    service_name     = string
    cpu_threshold    = optional(number, 85)
    memory_threshold = optional(number, 85)
  }))
  default = {}
}

variable "lambda" {
  description = "Lambda functions to watch, keyed by a static name: errors and throttles"
  type = map(object({
    function_name       = string
    errors_threshold    = optional(number, 0)
    throttles_threshold = optional(number, 0)
  }))
  default = {}
}

variable "sqs" {
  description = "SQS queues to watch, keyed by a static name: age of oldest message, and any message in the DLQ when dlq_name is set"
  type = map(object({
    queue_name      = string
    dlq_name        = optional(string)
    max_age_seconds = optional(number, 900)
  }))
  default = {}
}

variable "alarms" {
  description = "Any other metric alarms, keyed by a static name (used in the alarm name)"
  type = map(object({
    description         = optional(string)
    namespace           = string
    metric_name         = string
    dimensions          = optional(map(string), {})
    statistic           = optional(string, "Average")
    extended_statistic  = optional(string)
    comparison_operator = optional(string, "GreaterThanThreshold")
    threshold           = number
    period              = optional(number, 300)
    evaluation_periods  = optional(number, 3)
    datapoints_to_alarm = optional(number)
    treat_missing_data  = optional(string, "notBreaching")
  }))
  default = {}
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
