output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.lambda_repo.repository_url
}

output "ecr_repository_arn" {
  description = "The ARN of the ECR repository"
  value       = aws_ecr_repository.lambda_repo.arn
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.function.arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.function.function_name
}

output "lambda_function_invoke_arn" {
  description = "The invoke ARN of the Lambda function"
  value       = aws_lambda_function.function.invoke_arn
}

output "lambda_function_role_arn" {
  description = "The ARN of the IAM role created for the Lambda function"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_function_role_name" {
  description = "The name of the IAM role created for the Lambda function"
  value       = aws_iam_role.lambda_role.name
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_logs.arn
}
