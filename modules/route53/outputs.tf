output "zone_id" {
  description = "ID of the zone"
  value       = local.zone_id
}

output "zone_arn" {
  description = "ARN of the zone"
  value       = data.aws_route53_zone.this.arn
}

output "name_servers" {
  description = "Name servers to set at the registrar (public zones)"
  value       = data.aws_route53_zone.this.name_servers
}

output "record_fqdns" {
  description = "FQDNs keyed like var.records"
  value       = { for k, v in aws_route53_record.this : k => v.fqdn }
}
