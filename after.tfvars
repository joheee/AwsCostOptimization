environment = "after"

web_instance_type = "t4g.small"
web_arch          = "arm64"
web_volume_gb     = 20
web_volume_type   = "gp3"

db_instance_class = "db.t4g.micro"
db_multi_az       = false
db_storage_gb     = 20
db_storage_type   = "gp3"

enable_nat_gateway   = false
enable_elastic_ip    = false
unattached_volume_gb = 0
log_retention_days   = 14
enable_s3_lifecycle  = true

enable_schedule = true
