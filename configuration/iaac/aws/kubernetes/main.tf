# aws --version
# aws eks --region us-east-1 update-kubeconfig --name in28minutes-cluster
# Uses default VPC and Subnet. Create Your Own VPC and Private Subnets for Prod Usage.
# terraform-backend-state-in28minutes-123
# AKIA4AHVNOD7OOO6T4KI


terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 3.0"
    }
  }
}

terraform {
  backend "s3" {
    bucket = "mybucket" # Will be overridden from build
    key    = "path/to/my/key" # Will be overridden from build
    region = "us-east-1"
  }
}
resource "aws_s3_bucket" "bucket" {
    bucket        = "devops-app-data-123"
    force_destroy = true
    versioning {
      enabled = true
    }

    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
      }
    }
}

data "aws_vpc" "default-vpc" {
    default = true
}

data "aws_subnet_ids" "default_subnet" {
  vpc_id = data.aws_vpc.default-vpc.id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
 // version                = "~> 1.9"
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "presjkit-cluster"
  cluster_version = "1.17"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  cluster_encryption_config = [{
    provider_key_arn = "arn:aws:kms:eu-west-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    resources        = ["secrets"]
  }]

  vpc_id     = data.aws_vpc.default-vpc.id
  subnet_ids = ["subnet-0748f5d0412ddcb71", "subnet-05fbf91cab0e98313", "subnet-00377a54c78cb04d1"]
 

  node_groups = [
    {
      instance_type = "t2.micro"
      max_capacity  = 5
      desired_capacity = 3
      min_capacity  = 3
    }
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.in28minutes-cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.in28minutes-cluster.cluster_id
}


# We will use ServiceAccount to connect to K8S Cluster in CI/CD mode
# ServiceAccount needs permissions to create deployments 
# and services in default namespace
resource "kubernetes_cluster_role_binding" "example" {
  metadata {
    name = "fabric8-rbac"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "default"
  }
}

# Needed to set the default region
provider "aws" {
  region  = "us-east-1"
}
