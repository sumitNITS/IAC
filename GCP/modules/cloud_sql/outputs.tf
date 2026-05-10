output "instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = google_sql_database_instance.primary.name
}

output "instance_connection_name" {
  description = "Connection name of the Cloud SQL instance (for Cloud SQL Auth Proxy)"
  value       = google_sql_database_instance.primary.connection_name
}

output "private_ip_address" {
  description = "Private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.primary.private_ip_address
}

output "database_name" {
  description = "Name of the application database"
  value       = google_sql_database.app.name
}

output "secret_id" {
  description = "ID of the Secret Manager secret containing the DB password"
  value       = google_secret_manager_secret.db_password.id
}
