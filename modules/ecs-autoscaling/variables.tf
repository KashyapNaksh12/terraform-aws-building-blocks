variable "name" {
  description = "Name prefix for the scaling policies, usually the service name"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster the service runs in"
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service to scale"
  type        = string
}

variable "min_capacity" {
  description = "Minimum number of tasks"
  type        = number
}

variable "max_capacity" {
  description = "Maximum number of tasks"
  type        = number
}

variable "cpu_target" {
  description = "Target average CPU utilization in percent"
  type        = number
  default     = 70
}

variable "memory_target" {
  description = "Target average memory utilization in percent. Null skips the memory policy"
  type        = number
  default     = null
}

variable "scale_in_cooldown" {
  description = "Seconds to wait after a scale in before scaling in again"
  type        = number
  default     = 300
}

variable "scale_out_cooldown" {
  description = "Seconds to wait after a scale out before scaling out again"
  type        = number
  default     = 60
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
