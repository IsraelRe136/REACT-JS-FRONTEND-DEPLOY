provider "aws" {
  region = "us-east-2"  # Ohio

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "eks-cluster"
      Terraform   = "true"
    }
  }
}

# Provider Kubernetes se configurará después de crear el EKS
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}