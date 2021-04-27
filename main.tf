module "config_logs" {
  source  = "trussworks/logs/aws"
  version = "~> 10"

  s3_bucket_name     = local.config_logs_bucket_name
  allow_config       = true
  config_logs_prefix = "config"
  force_destroy      = true
}

module "config" {
  source                                  = "trussworks/config/aws"
  version                                 = "4.3.0"
  config_logs_bucket                      = module.config_logs.aws_logs_bucket
  config_logs_prefix                      = "config"
  check_cloudtrail_enabled                = true
  check_guard_duty                        = false
  check_s3_bucket_public_write_prohibited = true
  check_s3_bucket_ssl_requests_only       = true

  tags = {
    "Automation" = "Terraform"
    "Name"       = "main_config"
  }
}

data "aws_ami" "aws" {
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.20190115-x86_64-gp2"]
  }

  owners = ["amazon"]
}

resource "aws_security_group" "default_security_group" {
  name        = "default-security-group"
  description = "launch-wizard-1 created 2019-01-28T21:52:58.113+01:00"

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTPS"
    from_port        = 443
    protocol         = "tcp"
    to_port          = 443
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "MQTTS"
    from_port        = 8883
    to_port          = 8883
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Syncthing"
    from_port        = 22000
    to_port          = 22000
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "collectd udp"
    from_port        = 25826
    to_port          = 25826
    protocol         = "udp"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "collectd tcp"
    from_port        = 25826
    to_port          = 25826
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["80.100.196.53/32"]
  }
}

resource "aws_instance" "influxdb" {
  ami                     = data.aws_ami.aws.id
  instance_type           = "t3.small"
  availability_zone       = "eu-central-1b"
  ebs_optimized           = true
  disable_api_termination = false
  cpu_core_count          = 1
  cpu_threads_per_core    = 2
  hibernation             = false
  key_name                = "cloud-max-1"
  monitoring              = false
  security_groups         = [aws_security_group.default_security_group.name]
  iam_instance_profile    = aws_iam_instance_profile.influxdb_instance_profile.name
}

resource "aws_iam_instance_profile" "influxdb_instance_profile" {
  name = "influxdb_instance_profile"
  role = aws_iam_role.telegraf_cloudwatch_aws_role.id
}

resource "aws_ebs_volume" "influxdb_volume" {
  availability_zone = "eu-central-1b"
  iops              = 150
  type              = "gp2"
  size              = 50
  snapshot_id       = "snap-0ec16755d26518f7e"
}

resource "aws_volume_attachment" "influxdb_volume_attachment" {
  device_name = "/dev/xvda"
  instance_id = aws_instance.influxdb.id
  volume_id   = aws_ebs_volume.influxdb_volume.id
}

resource "aws_kms_key" "influxdb-backup-objects" {
  description             = "KMS key is used to encrypt bucket objects in influxdb"
  deletion_window_in_days = 7
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${local.influxdb_bucket_name}",
    ]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "*"
    ]
  }
}


data "aws_iam_policy_document" "deny_non_ssl_access" {
  # Force SSL access only
  statement {
    sid = "ForceSSLOnlyAccess"

    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      "arn:aws:s3:::${local.influxdb_bucket_name}",
    "arn:aws:s3:::${local.influxdb_bucket_name}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket" "edejong-influxdb-backup" {
  bucket = local.influxdb_bucket_name
  versioning {
    enabled = true
  }
  force_destroy = true
  policy        = data.aws_iam_policy_document.deny_non_ssl_access.json
  acl           = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.influxdb-backup-objects.id
      }
    }
  }
}

resource "aws_s3_bucket" "selenium_chromium_test" {
  bucket = "edj-selenium-chromium-test"
  versioning {
    enabled = true
  }
  force_destroy = false
  acl           = "private"
}

resource "aws_route53_zone" "dejongsoftwareengineering_zone" {
  name = "dejongsoftwareengineering.nl"
}

resource "aws_route53_record" "influx_to_instance" {
  name    = "influxdb.dejongsoftwareengineering.nl"
  type    = "CNAME"
  zone_id = aws_route53_zone.dejongsoftwareengineering_zone.id
  records = [aws_instance.influxdb.public_dns]
  ttl     = 300
}

resource "aws_route53_record" "grafana_to_instance" {
  name    = "grafana.dejongsoftwareengineering.nl"
  type    = "CNAME"
  zone_id = aws_route53_zone.dejongsoftwareengineering_zone.id
  records = [aws_instance.influxdb.public_dns]
  ttl     = 300
}

module "aws_static_website" {
  source = "github.com/gedejong/terraform-aws-static-website"
  providers = {
    aws.other     = aws
    aws.us-east-1 = aws.us-east-1
  }

  website-domain-main     = "dejongsoftwareengineering.nl"
  website-domain-redirect = "www.dejongsoftwareengineering.nl"

  tags = {
    "Project" : "recipes-site"
  }
}

resource "aws_default_vpc" "default" {
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_default_vpc.default.id

  ingress = []
  egress  = []
}
