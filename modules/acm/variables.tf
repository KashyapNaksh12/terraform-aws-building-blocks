variable "domain_name" {
  description = "Main domain for the certificate, e.g. example.com or *.example.com"
  type        = string
}

variable "subject_alternative_names" {
  description = "Extra domains on the same certificate"
  type        = list(string)
  default     = []
}

variable "key_algorithm" {
  description = "Key algorithm: RSA_2048, EC_prime256v1 or EC_secp384r1"
  type        = string
  default     = "RSA_2048"
}

variable "route53_zone_id" {
  description = "Route 53 zone to create the validation records in. Null means you add them yourself (see validation_records output)"
  type        = string
  default     = null
}

variable "wait_for_validation" {
  description = "Wait until the certificate is issued (only with route53_zone_id)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
