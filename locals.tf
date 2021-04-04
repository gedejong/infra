locals {
  config_logs_bucket_name = "edj-se-aws-config-logs"
  influxdb_bucket_name = "edejong-influxdb-backup"
  tags = {
    "managed-by": "terraform",
    "in-project": "infra"
  }
}


