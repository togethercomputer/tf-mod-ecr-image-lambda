variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "default_lambda_image" {
  description = "The default Docker image to use for Lambda functions"
  type        = string
  default     = "public.ecr.aws/lambda/nodejs:20"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "The encryption type to use for the repository. Valid values are AES256 or KMS"
  type        = string
  default     = "AES256"
}

variable "release_image_retention_count" {
  description = "The number of images to keep in the repository with v-prefixed tags"
  type        = number
  default     = 100
}

variable "non_release_image_retention_count" {
  description = "The number of images to keep in the repository"
  type        = number
  default     = 50
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "timeout" {
  description = "The amount of time your Lambda Function has to run in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda Function can use at runtime"
  type        = number
  default     = 128
}

variable "initial_image_uri" {
  description = "Initial image URI to use for Lambda function"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "List of subnet IDs associated with the Lambda function (VPC)"
  type        = list(string)
  default     = null
}

variable "security_group_ids" {
  description = "List of security group IDs associated with the Lambda function (VPC)"
  type        = list(string)
  default     = null
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "Number of days to retain Lambda function logs"
  type        = number
  default     = 14
}
