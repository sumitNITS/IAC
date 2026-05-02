# Root TFLint configuration for the entire IAC project
# Run:  tflint --init  (first time only)
# Then: tflint --recursive --format compact

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "~> 0.30"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "google" {
  enabled = true
  version = "~> 0.27"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}

# Optional: ignore certain directories
# config {
#   ignore_module = {
#     # "some_module" = true
#   }
# }

# Optional: disable specific rules globally if too noisy
# rule "terraform_required_version" {
#   enabled = false
# }
