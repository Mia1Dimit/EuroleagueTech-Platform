# ============================================================================
# GitHub Actions OIDC — keyless authentication for CI/CD
# ============================================================================

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  # GitHub's OIDC thumbprints (primary + backup)
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name = "spotech-dev-github-oidc"
  }
}

resource "aws_iam_role" "github_actions" {
  name = "spotech-dev-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # Restrict to this repo only — branches + PR refs
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
        }
      }
    }]
  })

  tags = {
    Name        = "spotech-dev-github-actions-role"
    ManagedBy   = "Terraform"
    Purpose     = "GitHub Actions CI/CD — OIDC keyless auth"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name = "spotech-dev-github-actions-deploy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Terraform remote state
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket",
                  "s3:GetBucketVersioning", "s3:GetEncryptionConfiguration"]
        Resource = [
          "arn:aws:s3:::spotech-dev-s3-tfstate-${data.aws_caller_identity.current.account_id}-eu-west-1-an",
          "arn:aws:s3:::spotech-dev-s3-tfstate-${data.aws_caller_identity.current.account_id}-eu-west-1-an/*"
        ]
      },
      # State lock table
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:DescribeTable"]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/spotech-dev-ddb-tfstatelock"
      },
      # Lambda — deploy + manage
      {
        Effect   = "Allow"
        Action   = ["lambda:GetFunction", "lambda:UpdateFunctionCode", "lambda:UpdateFunctionConfiguration",
                    "lambda:CreateFunction", "lambda:DeleteFunction", "lambda:AddPermission",
                    "lambda:RemovePermission", "lambda:GetFunctionConfiguration",
                    "lambda:ListVersionsByFunction", "lambda:PublishVersion", "lambda:TagResource"]
        Resource = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:spotech-dev-*"
      },
      # S3 — frontend bucket sync
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:DeleteObject", "s3:GetObject", "s3:ListBucket",
                    "s3:GetBucketLocation", "s3:GetBucketCORS", "s3:PutBucketCORS",
                    "s3:GetBucketPolicy", "s3:PutBucketPolicy", "s3:GetBucketAcl",
                    "s3:GetBucketPublicAccessBlock", "s3:PutBucketPublicAccessBlock",
                    "s3:GetBucketVersioning", "s3:GetEncryptionConfiguration",
                    "s3:GetLifecycleConfiguration", "s3:PutLifecycleConfiguration",
                    "s3:GetBucketTagging", "s3:PutBucketTagging"]
        Resource = [
          "arn:aws:s3:::spotech-dev-*",
          "arn:aws:s3:::spotech-dev-*/*"
        ]
      },
      # CloudFront invalidation
      {
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation", "cloudfront:GetDistribution",
                    "cloudfront:UpdateDistribution", "cloudfront:GetDistributionConfig",
                    "cloudfront:ListDistributions", "cloudfront:TagResource",
                    "cloudfront:CreateOriginAccessControl", "cloudfront:GetOriginAccessControl",
                    "cloudfront:DeleteOriginAccessControl", "cloudfront:ListOriginAccessControls"]
        Resource = "*"
      },
      # DynamoDB — manage project table
      {
        Effect   = "Allow"
        Action   = ["dynamodb:DescribeTable", "dynamodb:CreateTable", "dynamodb:DeleteTable",
                    "dynamodb:UpdateTable", "dynamodb:ListTagsOfResource", "dynamodb:TagResource",
                    "dynamodb:UntagResource", "dynamodb:DescribeTimeToLive", "dynamodb:DescribeContinuousBackups",
                    "dynamodb:DescribeGlobalTable"]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/spotech-dev-*"
      },
      # API Gateway
      {
        Effect   = "Allow"
        Action   = ["apigateway:GET", "apigateway:POST", "apigateway:PUT",
                    "apigateway:PATCH", "apigateway:DELETE", "apigateway:TagResource"]
        Resource = "arn:aws:apigateway:${var.aws_region}::*"
      },
      # CloudWatch Logs + Dashboard + Alarms
      {
        Effect = "Allow"
        Action = ["logs:CreateLogGroup", "logs:DeleteLogGroup", "logs:DescribeLogGroups",
                  "logs:ListTagsLogGroup", "logs:PutRetentionPolicy", "logs:TagLogGroup",
                  "logs:UntagLogGroup", "logs:TagResource", "cloudwatch:PutDashboard",
                  "cloudwatch:GetDashboard", "cloudwatch:DeleteDashboards", "cloudwatch:ListDashboards",
                  "cloudwatch:PutMetricAlarm", "cloudwatch:DeleteAlarms", "cloudwatch:DescribeAlarms",
                  "cloudwatch:TagResource"]
        Resource = "*"
      },
      # SNS
      {
        Effect   = "Allow"
        Action   = ["sns:CreateTopic", "sns:DeleteTopic", "sns:GetTopicAttributes",
                    "sns:SetTopicAttributes", "sns:Subscribe", "sns:Unsubscribe",
                    "sns:ListTagsForResource", "sns:TagResource", "sns:UntagResource"]
        Resource = "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:spotech-dev-*"
      },
      # IAM — manage Lambda execution roles + OIDC provider
      {
        Effect   = "Allow"
        Action   = ["iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:UpdateRole",
                    "iam:PutRolePolicy", "iam:GetRolePolicy", "iam:DeleteRolePolicy",
                    "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:ListRolePolicies",
                    "iam:ListAttachedRolePolicies", "iam:TagRole", "iam:UntagRole",
                    "iam:PassRole", "iam:CreateOpenIDConnectProvider",
                    "iam:GetOpenIDConnectProvider", "iam:DeleteOpenIDConnectProvider",
                    "iam:TagOpenIDConnectProvider", "iam:UpdateOpenIDConnectProviderThumbprint"]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/spotech-dev-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        ]
      }
    ]
  })
}
