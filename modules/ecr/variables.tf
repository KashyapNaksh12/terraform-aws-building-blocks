variable "name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "MUTABLE or IMMUTABLE. IMMUTABLE prevents overwriting existing tags"
  type        = string
  default     = "IMMUTABLE"
}

variable "scan_on_push" {
  description = "Scan images for vulnerabilities on push"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption. Null uses AES256"
  type        = string
  default     = null
}

variable "force_delete" {
  description = "Delete the repository even if it contains images"
  type        = bool
  default     = false
}

variable "max_image_count" {
  description = "Keep only this many tagged images (lifecycle policy). 0 disables the rule"
  type        = number
  default     = 30
}

variable "untagged_image_expiry_days" {
  description = "Expire untagged images after this many days. 0 disables the rule"
  type        = number
  default     = 7
}

variable "read_access_arns" {
  description = "IAM principal ARNs (e.g. other accounts) allowed to pull images"
  type        = list(string)
  default     = []
}

variable "read_write_access_arns" {
  description = "IAM principal ARNs allowed to push and pull images (e.g. a CI role)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
