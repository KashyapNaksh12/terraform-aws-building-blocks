output "certificate_arn" {
  description = "ARN of the certificate. When validated through Route 53 this only resolves once it's issued"
  value       = try(aws_acm_certificate_validation.this[0].certificate_arn, aws_acm_certificate.this.arn)
}

output "certificate_domain_name" {
  description = "Main domain of the certificate"
  value       = aws_acm_certificate.this.domain_name
}

output "validation_records" {
  description = "DNS records that prove domain ownership. Add these yourself if not using route53_zone_id"
  value = distinct([
    for dvo in aws_acm_certificate.this.domain_validation_options : {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  ])
}
