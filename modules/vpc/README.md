# vpc

VPC with public, private and database subnets spread over the AZs you pass in. NAT can be a single gateway (cheap) or one per AZ. Also sets up the S3 gateway endpoint, a DB subnet group and optionally flow logs to CloudWatch.

## Usage

```hcl
module "vpc" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/vpc?ref=v1.0.0"

  name             = "prod"
  cidr_block       = "10.0.0.0/16"
  azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets   = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  private_subnets  = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  database_subnets = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]

  single_nat_gateway = false
  enable_flow_logs   = true

  tags = { Environment = "prod" }
}
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name prefix applied to all VPC resources | `string` | n/a | **yes** |
| `cidr_block` | IPv4 CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| `azs` | AZs to use. Subnet lists line up with this by index | `list(string)` | n/a | **yes** |
| `public_subnets` | CIDR blocks for public subnets (one per AZ) | `list(string)` | `[]` | no |
| `private_subnets` | CIDR blocks for private (application) subnets (one per AZ) | `list(string)` | `[]` | no |
| `database_subnets` | CIDR blocks for isolated database subnets (one per AZ). No route to the internet | `list(string)` | `[]` | no |
| `enable_dns_hostnames` | Enable DNS hostnames in the VPC | `bool` | `true` | no |
| `enable_dns_support` | Enable DNS support in the VPC | `bool` | `true` | no |
| `map_public_ip_on_launch` | Auto-assign public IPs to instances launched in public subnets | `bool` | `false` | no |
| `enable_nat_gateway` | Create NAT gateway(s) so private subnets can reach the internet | `bool` | `true` | no |
| `single_nat_gateway` | Use one shared NAT gateway instead of one per AZ (cheaper, less resilient) | `bool` | `true` | no |
| `create_database_subnet_group` | Create an RDS DB subnet group from the database subnets | `bool` | `true` | no |
| `enable_s3_gateway_endpoint` | Add an S3 gateway endpoint (it's free) | `bool` | `true` | no |
| `enable_flow_logs` | Send VPC flow logs to CloudWatch Logs | `bool` | `false` | no |
| `flow_logs_retention_days` | Retention in days for the flow logs log group | `number` | `30` | no |
| `flow_logs_traffic_type` | Traffic type to capture: ACCEPT, REJECT, or ALL | `string` | `"ALL"` | no |
| `public_subnet_tags` | Extra tags for public subnets (e.g. kubernetes.io/role/elb = 1) | `map(string)` | `{}` | no |
| `private_subnet_tags` | Extra tags for private subnets (e.g. kubernetes.io/role/internal-elb = 1) | `map(string)` | `{}` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | ID of the VPC |
| `vpc_arn` | ARN of the VPC |
| `vpc_cidr_block` | CIDR block of the VPC |
| `internet_gateway_id` | ID of the internet gateway (null if no public subnets) |
| `public_subnet_ids` | IDs of the public subnets |
| `private_subnet_ids` | IDs of the private subnets |
| `database_subnet_ids` | IDs of the database subnets |
| `database_subnet_group_name` | Name of the RDS DB subnet group (null if not created) |
| `public_route_table_ids` | IDs of the public route tables |
| `private_route_table_ids` | IDs of the private route tables |
| `database_route_table_ids` | IDs of the database route tables |
| `nat_gateway_ids` | IDs of the NAT gateways |
| `nat_public_ips` | Elastic IPs attached to the NAT gateways |
| `azs` | Availability zones used |
<!-- END_TF_DOCS -->
