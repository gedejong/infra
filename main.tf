terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "edj-personal"

    workspaces {
      name = "infra"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.34.0"
    }
  }
}

provider "aws" {
  region                  = "eu-central-1"
  shared_credentials_file = "~/.aws/credentials"
  access_key              = var.access_key
  secret_key              = var.secret_key
}

data "aws_ami" "aws" {
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.20190115-x86_64-gp2"]
  }

  owners = ["amazon"]
}

resource "aws_security_group" "default_security_group" {
  name = "default-security-group"
  description = "launch-wizard-1 created 2019-01-28T21:52:58.113+01:00"

  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port = 443
    protocol  = "tcp"
    to_port   = 443
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MQTTS"
    from_port = 8883
    to_port   = 8883
    protocol  = "tcp"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Syncthing"
    from_port = 22000
    to_port   = 22000
    protocol  = "tcp"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "collectd udp"
    from_port = 25826
    to_port   = 25826
    protocol  = "udp"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "collectd tcp"
    from_port = 25826
    to_port   = 25826
    protocol  = "tcp"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from my IP"
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["80.100.196.53/32"]
  }
}

resource "aws_instance" "influxdb" {
  ami           = data.aws_ami.aws.id
  instance_type = "t3.small"
  availability_zone = "eu-central-1b"
  ebs_optimized = true
  disable_api_termination = false
  cpu_core_count = 1
  cpu_threads_per_core = 2
  hibernation = false
  key_name = "cloud-max-1"
  monitoring = false
  security_groups = [aws_security_group.default_security_group.name]
}

resource "aws_ebs_volume" "influxdb_volume" {
  availability_zone = "eu-central-1b"
  iops = 150
  type = "gp2"
  size = 50
  snapshot_id = "snap-0ec16755d26518f7e"
}

resource "aws_volume_attachment" "influxdb_volume_attachment" {
  device_name = "/dev/xvda"
  instance_id = aws_instance.influxdb.id
  volume_id   = aws_ebs_volume.influxdb_volume.id
}

resource "aws_route53_zone" "dejongsoftwareengineering_zone" {
  name = "dejongsoftwareengineering.nl"
}

resource "aws_route53_record" "influx_to_instance" {
  name    = "influxdb.dejongsoftwareengineering.nl"
  type    = "CNAME"
  zone_id = aws_route53_zone.dejongsoftwareengineering_zone.id
  records = [aws_instance.influxdb.public_dns]
  ttl = 300
}

resource "aws_route53_record" "grafana_to_instance" {
  name    = "grafana.dejongsoftwareengineering.nl"
  type    = "CNAME"
  zone_id = aws_route53_zone.dejongsoftwareengineering_zone.id
  records = [aws_instance.influxdb.public_dns]
  ttl = 300
}

module "aws_static_website" {
  source = "github.com/gedejong/terraform-aws-static-website"

  website-domain-main     = "dejongsoftwareengineering.nl"
  website-domain-redirect = "www.dejongsoftwareengineering.nl"

  tags = {
    "Project" : "recipes-site"
  }
}
