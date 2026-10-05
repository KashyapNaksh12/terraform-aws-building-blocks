variable "name" {
  description = "Name prefix applied to all VPC resources"
  type        = string
}

variable "cidr_block" {
  description = "IPv4 CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "cidr_block must be a valid IPv4 CIDR"
  }
}

variable "azs" {
  description = "AZs to use. Subnet lists line up with this by index"
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "CIDR blocks for private (application) subnets (one per AZ)"
  type        = list(string)
  default     = []
}

variable "database_subnets" {
  description = "CIDR blocks for isolated database subnets (one per AZ). No route to the internet"
  type        = list(string)
  default     = []
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch" {
  description = "Auto-assign public IPs to instances launched in public subnets"
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Create NAT gateway(s) so private subnets can reach the internet"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway instead of one per AZ (cheaper, less resilient)"
  type        = bool
  default     = true
}

variable "create_database_subnet_group" {
  description = "Create an RDS DB subnet group from the database subnets"
  type        = bool
  default     = true
}

variable "enable_s3_gateway_endpoint" {
  description = "Add an S3 gateway endpoint (it's free)"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Send VPC flow logs to CloudWatch Logs"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "Retention in days for the flow logs log group"
  type        = number
  default     = 30
}

variable "flow_logs_traffic_type" {
  description = "Traffic type to capture: ACCEPT, REJECT, or ALL"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_logs_traffic_type)
    error_message = "flow_logs_traffic_type must be ACCEPT, REJECT, or ALL"
  }
}

variable "public_subnet_tags" {
  description = "Extra tags for public subnets (e.g. kubernetes.io/role/elb = 1)"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Extra tags for private subnets (e.g. kubernetes.io/role/internal-elb = 1)"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
