# ec2

Single EC2 instance. Uses Amazon Linux 2023 unless you pass `ami_id`, forces IMDSv2 and encrypts the volumes. By default it also creates a role with SSM attached so you can get a shell with `aws ssm start-session` and skip SSH keys.

## Usage

```hcl
module "web" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/ec2?ref=v1.0.0"

  name                   = "web-1"
  instance_type          = "t3.small"
  subnet_id              = module.vpc.private_subnet_ids[0]
  vpc_security_group_ids = [module.app_sg.security_group_id]

  iam_role_policy_arns = {
    cloudwatch = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  ebs_volumes = {
    "/dev/sdf" = { size = 50 }
  }

  user_data = file("${path.module}/bootstrap.sh")
}
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name of the instance | `string` | n/a | **yes** |
| `ami_id` | AMI to use. Defaults to the latest Amazon Linux 2023 | `string` | `null` | no |
| `architecture` | CPU architecture used for the default AMI lookup: x86_64 or arm64 | `string` | `"x86_64"` | no |
| `instance_type` | EC2 instance type | `string` | `"t3.micro"` | no |
| `subnet_id` | Subnet to launch the instance in | `string` | n/a | **yes** |
| `vpc_security_group_ids` | Security group IDs to attach | `list(string)` | `[]` | no |
| `key_name` | EC2 key pair name. Usually not needed since SSM works out of the box | `string` | `null` | no |
| `associate_public_ip_address` | Associate a public IP address (only meaningful in public subnets) | `bool` | `false` | no |
| `create_eip` | Allocate and attach an Elastic IP to the instance | `bool` | `false` | no |
| `user_data` | User data script (plain text; it is base64-encoded by the provider) | `string` | `null` | no |
| `user_data_replace_on_change` | Recreate the instance when user_data changes | `bool` | `false` | no |
| `create_iam_instance_profile` | Create a role/instance profile with SSM access | `bool` | `true` | no |
| `iam_role_policy_arns` | Extra policies for the instance role, as name => arn | `map(string)` | `{}` | no |
| `iam_instance_profile` | Existing instance profile, used when create_iam_instance_profile is false | `string` | `null` | no |
| `root_volume_size` | Root EBS volume size in GiB | `number` | `20` | no |
| `root_volume_type` | Root EBS volume type | `string` | `"gp3"` | no |
| `kms_key_id` | KMS key ARN for EBS encryption. Null uses the AWS-managed EBS key | `string` | `null` | no |
| `ebs_volumes` | Extra EBS volumes keyed by device name, e.g. /dev/sdf | `map(object)` | `{}` | no |
| `monitoring` | Enable detailed CloudWatch monitoring | `bool` | `false` | no |
| `disable_api_termination` | Enable termination protection | `bool` | `false` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `instance_id` | ID of the instance |
| `instance_arn` | ARN of the instance |
| `private_ip` | Private IP address of the instance |
| `public_ip` | Public IP (the Elastic IP when create_eip = true) |
| `availability_zone` | Availability zone of the instance |
| `iam_role_name` | Name of the created IAM role (null if not created) |
| `iam_role_arn` | ARN of the created IAM role (null if not created) |
| `ami_id` | AMI the instance was launched from |
<!-- END_TF_DOCS -->
