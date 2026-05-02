# Root TFLint configuration for the entire IAC project
# Run:  tflint --init  (first time only)
# Then: tflint --recursive --format compact

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.47.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "google" {
  enabled = true
  version = "0.38.0"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}

# Optional: ignore certain directories
# config {
#   ignore_module = {
#     # "some_module" = true
#   }
# }

# Disable rules that fail on variable references (can't be evaluated at lint time)
rule "google_compute_instance_invalid_machine_type" {
  enabled = false
}

rule "google_container_node_pool_invalid_machine_type" {
  enabled = false
}

rule "aws_instance_invalid_type" {
  enabled = false
}
