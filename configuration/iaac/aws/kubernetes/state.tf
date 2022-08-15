terraform {
  backend "s3" {
    bucket = "terraform-backend-state-in28minutes-123" # Will be overridden from build
    key    = "kubernetes-dev.tfstate" # Will be overridden from build
    region = "us-east-1"
  }
}