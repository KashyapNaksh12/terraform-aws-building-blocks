variable "name" {
  description = "Name of the instance"
  type        = string
}

variable "ami_id" {
  description = "AMI to use. Defaults to the latest Amazon Linux 2023"
  type        = string
  default     = null
}

variable "architecture" {
  description = "CPU architecture used for the default AMI lookup: x86_64 or arm64"
  type        = string
  default     = "x86_64"

  validation {
    condition     = contains(["x86_64", "arm64"], var.architecture)
    error_message = "architecture must be x86_64 or arm64"
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet to launch the instance in"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "Security group IDs to attach"
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "EC2 key pair name. Usually not needed since SSM works out of the box"
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Associate a public IP address (only meaningful in public subnets)"
  type        = bool
  default     = false
}

variable "create_eip" {
  description = "Allocate and attach an Elastic IP to the instance"
  type        = bool
  default     = false
}

variable "user_data" {
  description = "User data script (plain text; it is base64-encoded by the provider)"
  type        = string
  default     = null
}

variable "user_data_replace_on_change" {
  description = "Recreate the instance when user_data changes"
  type        = bool
  default     = false
}

variable "create_iam_instance_profile" {
  description = "Create a role/instance profile with SSM access"
  type        = bool
  default     = true
}

variable "iam_role_policy_arns" {
  description = "Extra policies for the instance role, as name => arn"
  type        = map(string)
  default     = {}
}

variable "iam_instance_profile" {
  description = "Existing instance profile, used when create_iam_instance_profile is false"
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Root EBS volume type"
  type        = string
  default     = "gp3"
}

variable "kms_key_id" {
  description = "KMS key ARN for EBS encryption. Null uses the AWS-managed EBS key"
  type        = string
  default     = null
}

variable "ebs_volumes" {
  description = "Extra EBS volumes keyed by device name, e.g. /dev/sdf"
  type = map(object({
    size       = number
    type       = optional(string, "gp3")
    iops       = optional(number)
    throughput = optional(number)
  }))
  default = {}
}

variable "monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "disable_api_termination" {
  description = "Enable termination protection"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
