terraform {
  backend "s3" {
    bucket         = "terraform-backend-state-5678" # Will be overridden from build
    key            = "kubernetes-dev.tfstate" # Will be overridden from build
    region         = "us-east-1"
  }
}