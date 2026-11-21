locals {
  name_prefix = "${var.project}-${var.environment}"
}

module "network" {
  source = "./modules/network"

  name_prefix        = local.name_prefix
  enable_nat_gateway = var.enable_nat_gateway
}

module "web" {
  source = "./modules/web"

  name_prefix          = local.name_prefix
  environment          = var.environment
  vpc_id               = module.network.vpc_id
  subnet_id            = module.network.public_subnet_ids[0]
  instance_type        = var.web_instance_type
  arch                 = var.web_arch
  volume_gb            = var.web_volume_gb
  volume_type          = var.web_volume_type
  enable_elastic_ip    = var.enable_elastic_ip
  unattached_volume_gb = var.unattached_volume_gb
}

module "database" {
  source = "./modules/database"

  name_prefix           = local.name_prefix
  vpc_id                = module.network.vpc_id
  subnet_ids            = module.network.public_subnet_ids
  web_security_group_id = module.web.security_group_id
  instance_class        = var.db_instance_class
  multi_az              = var.db_multi_az
  storage_gb            = var.db_storage_gb
  storage_type          = var.db_storage_type
}

module "storage" {
  source = "./modules/storage"

  name_prefix         = local.name_prefix
  enable_s3_lifecycle = var.enable_s3_lifecycle
  log_retention_days  = var.log_retention_days
}

module "schedule" {
  source = "./modules/schedule"

  name_prefix   = local.name_prefix
  enabled       = var.enable_schedule
  timezone      = var.schedule_timezone
  stop_cron     = var.schedule_stop_cron
  start_cron    = var.schedule_start_cron
  instance_id   = module.web.instance_id
  instance_arn  = module.web.instance_arn
  db_identifier = module.database.identifier
  db_arn        = module.database.arn
}
