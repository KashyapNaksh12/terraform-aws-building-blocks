variable "name" {
  description = "Name of the EventBridge bus"
  type        = string
}

variable "description" {
  description = "Description of the event bus"
  type        = string
  default     = null
}

variable "rules" {
  description = "Rules keyed by stable names; each rule can define an event pattern or schedule and optional targets"
  type = map(object({
    description         = optional(string)
    event_pattern       = optional(string)
    schedule_expression = optional(string)
    state               = optional(string, "ENABLED")
    targets = optional(map(object({
      arn        = string
      role_arn   = optional(string)
      input      = optional(string)
      input_path = optional(string)
      input_transformer = optional(object({
        input_paths    = optional(map(string), {})
        input_template = string
      }))
      dead_letter_arn    = optional(string)
      max_event_age      = optional(number)
      max_retry_attempts = optional(number)
    })), {})
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to the event bus"
  type        = map(string)
  default     = {}
}
