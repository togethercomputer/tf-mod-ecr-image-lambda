/**
 * # Terraform Lambda ECR Module
 *
 * This module creates an ECR repository and Lambda function with image configuration.
 * It's designed to work with CI/CD pipelines for image updates.
 */

################################################################################
# ECR Repository
################################################################################

resource "aws_ecr_repository" "lambda_repo" {
  name                 = var.ecr_repository_name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
  }

  tags = var.tags
}

locals {
  default_image_tag = "default"
  ecr_image_uri     = "${aws_ecr_repository.lambda_repo.repository_url}:${local.default_image_tag}"
}

# Push a default image to ECR, without this Lambda provisioning will fail
resource "null_resource" "push_default_image" {
  depends_on = [aws_ecr_repository.lambda_repo]

  triggers = {
    ecr_repository_url = aws_ecr_repository.lambda_repo.repository_url
  }

  provisioner "local-exec" {
    command = <<EOF
      #!/bin/bash
      set -e
      
      # Echo commands for debugging
      echo "Starting Docker image push process..."
      
      # Pull the base image
      echo "Pulling base image..."
      docker pull ${var.default_lambda_image}
      
      # Tag the image for our ECR repository with 'latest' tag
      echo "Tagging image..."
      docker tag ${var.default_lambda_image} ${local.ecr_image_uri}
      
      # Verify the tag was created
      echo "Verifying tag..."
      docker images | grep ${aws_ecr_repository.lambda_repo.name}
      
      # Get ECR login token
      echo "Logging into ECR..."
      aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com

      # Push to ECR
      echo "Pushing to ECR..."
      docker push ${local.ecr_image_uri}
      
      echo "Docker push process completed."
    EOF
  }
}

# Get current AWS account info
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "lambda_repo" {
  repository = aws_ecr_repository.lambda_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.release_image_retention_count} release images (v-prefixed tags)"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = var.release_image_retention_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the last ${var.non_release_image_retention_count} non-release images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.non_release_image_retention_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Repository Policy for Lambda access
resource "aws_ecr_repository_policy" "lambda_repo" {
  repository = aws_ecr_repository.lambda_repo.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LambdaECRImageRetrievalPolicy"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      }
    ]
  })
}

################################################################################
# Lambda Function
################################################################################

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# CloudWatch Logs Policy
resource "aws_iam_policy" "lambda_logging" {
  name        = "${var.function_name}-logging-policy"
  description = "IAM policy for Lambda logging to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach logging policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

# Attach ECR pull permissions to Lambda role
resource "aws_iam_role_policy" "lambda_ecr_pull" {
  name = "${var.function_name}-ecr-pull-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = aws_ecr_repository.lambda_repo.arn
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "function" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_role.arn
  timeout       = var.timeout
  memory_size   = var.memory_size

  package_type = "Image"

  # Use the pushed image from our ECR repository 
  # This is a copy of ${var.default_lambda_image} initially
  # Will be managed/replaced outside terraform lifecycle by CI/CD
  image_uri = local.ecr_image_uri

  depends_on = [null_resource.push_default_image]

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = var.environment_variables
  }


  lifecycle {
    # Prevent Terraform from updating the image_uri on subsequent applies
    # image_uri is managed/replaced outside the terraform lifecycle
    # By a CI/CD pipeline
    ignore_changes = [image_uri]
  }

  tags = var.tags
}

# CloudWatch Log Group with retention
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}
