terraform {
  # GCS bucket for state storage
  backend "gcs" {
    bucket = "value"
    prefix = "dev/terraform.tfstate"
  }
}
