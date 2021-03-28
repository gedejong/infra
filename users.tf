resource "aws_iam_user" "recipes" {
  name = "github_actions_recipes"
  path = "/system/"
}

resource "aws_iam_access_key" "lb" {
  user = aws_iam_user.recipes.name
}

/*
data "aws_iam_policy_document" "recipes_pd" {
  statement {
    actions = [ ]
    effect = "Allow"
    resources = [module.aws_static_website]
  }
}

resource "aws_iam_user_policy" "lb_ro" {
  name = "test"
  user = aws_iam_user.lb.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
*/