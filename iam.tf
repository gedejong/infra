resource "aws_iam_user" "github_actions_recipes" {
  name = "github_actions_recipes"
  path = "/system/"
  tags = local.tags
}

resource "aws_iam_user" "edejong" {
  name = "edejong"
  path = "/"
  tags = local.tags
}

data "aws_iam_policy_document" "github_actions_recipes_policy_document" {
  statement {
    sid    = "allowS3AccessForUpdateWebsite"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetBucketLocation",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${module.aws_static_website.website_root_s3_bucket}/*",
      "arn:aws:s3:::${module.aws_static_website.website_root_s3_bucket}"
    ]
  }
}

resource "aws_iam_group" "github_actions_recipes" {
  name = "github_actions_recipes"
  path = "/system/"
}

resource "aws_iam_group" "administrators" {
  name = "administrators"
  path = "/"
}

resource "aws_iam_group" "accounting" {
  name = "accounting"
  path = "/"
}

resource "aws_iam_group_membership" "github_actions_recipes_membership" {
  group = aws_iam_group.github_actions_recipes.id
  name  = "github_actions_recipes_self_membership"
  users = [aws_iam_user.github_actions_recipes.id]
}

resource "aws_iam_user_group_membership" "edejong" {
  groups = [aws_iam_group.administrators.id, aws_iam_group.accounting.id]
  user   = aws_iam_user.edejong.id
}

resource "aws_iam_group_policy" "github_actions_recipes_policy" {
  group  = aws_iam_group.github_actions_recipes.id
  policy = data.aws_iam_policy_document.github_actions_recipes_policy_document.json
}

data "aws_iam_policy" "administrator_access" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy" "billing_access" {
  arn = "arn:aws:iam::aws:policy/job-function/Billing"
}

resource "aws_iam_group_policy_attachment" "administrators_policy" {
  group      = aws_iam_group.administrators.id
  policy_arn = data.aws_iam_policy.administrator_access.arn
}

resource "aws_iam_group_policy_attachment" "accounting_policy" {
  group      = aws_iam_group.accounting.id
  policy_arn = data.aws_iam_policy.billing_access.arn
}

data "aws_iam_policy_document" "telegraf_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "telegraf_cloudwatch_aws_role" {
  name               = "telegraf_cloudwatch_aws_role"
  description        = "The role which retrieves data from Cloudwatch and reports it to InfluxDB"
  assume_role_policy = data.aws_iam_policy_document.telegraf_assume_role_policy.json
}

data "aws_iam_policy_document" "telegraf_cloudwatch_metrics_read" {
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:GetMetricStream",
      "cloudwatch:ListMetrics",
      "cloudwatch:ListMetricStreams",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "telegraf_cloudwatch_aws_role_metrics_read" {
  policy = data.aws_iam_policy_document.telegraf_cloudwatch_metrics_read.json
  role   = aws_iam_role.telegraf_cloudwatch_aws_role.id
  name   = "telegraf_cloudwatch_aws_role_metrics_read"
}
