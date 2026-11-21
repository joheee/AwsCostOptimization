output "web_public_ip" {
  description = "Public IP of the web server (curl this)."
  value       = module.web.public_ip
}

output "web_instance_id" {
  value = module.web.instance_id
}

output "db_identifier" {
  value = module.database.identifier
}

output "backup_bucket" {
  value = module.storage.bucket_id
}
