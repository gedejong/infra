resource "aws_iam_user" "recipes" {
  name = "github_actions_recipes"
  path = "/system/"
}

/*
data "aws_iam_policy_document" "recipes_pd" {
  statement {
    actions = [
      "s3:DeleteObject",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${module.aws_static_website.website_root_s3_bucket}",
      "arn:aws:s3:::${module.aws_static_website.website_root_s3_bucket}/*",
    ]
  }
}

resource "aws_iam_user_policy" "lb_ro" {
  name   = "test"
  user   = aws_iam_user.recipes.name
  policy = data.aws_iam_policy_document.recipes_pd.json
}
*/