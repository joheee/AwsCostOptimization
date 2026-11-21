environment = "before"

web_instance_type = "m7i.xlarge"
web_arch          = "x86_64"
web_volume_gb     = 200
web_volume_type   = "gp2"

db_instance_class = "db.m7i.large"
db_multi_az       = true
db_storage_gb     = 200
db_storage_type   = "gp2"

enable_nat_gateway   = true
enable_elastic_ip    = true
unattached_volume_gb = 500
log_retention_days   = 0
enable_s3_lifecycle  = false

enable_schedule = false
