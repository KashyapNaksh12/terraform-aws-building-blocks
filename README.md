# terraform-aws-building-blocks

Terraform modules we use for the usual AWS stuff. Each folder under `modules/` is standalone.

| Module | |
|--------|---|
| [vpc](modules/vpc) | VPC, subnets (public / private / db), IGW, NAT, S3 endpoint, flow logs |
| [security-group](modules/security-group) | SG with rules passed in as maps |
| [ec2](modules/ec2) | EC2 instance with SSM role, IMDSv2, encrypted EBS |
| [s3](modules/s3) | Private bucket with versioning, encryption, lifecycle rules |
| [iam-role](modules/iam-role) | IAM role for services, other accounts or GitHub Actions (OIDC) |
| [rds](modules/rds) | RDS postgres/mysql/mariadb, password kept in Secrets Manager |
| [alb](modules/alb) | ALB + target group, HTTP to HTTPS redirect if you give it a cert |
| [ecr](modules/ecr) | ECR repo with scanning and image cleanup |
| [lambda](modules/lambda) | Lambda function, role and log group |
| [dynamodb](modules/dynamodb) | DynamoDB table with GSIs, TTL, streams |

Needs Terraform >= 1.5 and AWS provider >= 5.81 (works on 6.x).

## Using a module

Point `source` at this repo and pin a tag:

```hcl
module "vpc" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/vpc?ref=v1.0.0"

  name            = "prod"
  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]
}
```

Inputs/outputs for each module are in its README.

The modules don't have provider blocks, so region, default tags, assume role etc. go in your root config.

Policy ARNs, targets and rules are passed as maps rather than lists, so `for_each` keys stay the same even when the values are only known after apply.

## Example

`examples/complete` puts everything together: VPC, ALB in front of two EC2 instances, Postgres, S3, DynamoDB, ECR, a Lambda and optionally a role for GitHub Actions.

```bash
cd examples/complete
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
```

Heads up, this costs money (NAT gateway, RDS, ALB). Destroy it when you're done.

## Dev

```bash
terraform fmt -recursive
pre-commit install
```

CI runs fmt, validate, tflint and a trivy scan on every PR.

To release, tag it and push the tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```
