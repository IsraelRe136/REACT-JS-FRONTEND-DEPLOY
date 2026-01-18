
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr


  azs = ["us-east-2a", "us-east-2b", "us-east-2c"]
  
  
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  

  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

 
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true


  public_subnet_tags = {
    "kubernetes.io/role/elb"              = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"     = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.15"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version



 
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  # Endpoint del cluster (puede ser público o privado)
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

 
  cluster_service_ipv4_cidr = "172.20.0.0/16"
  
  
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
         most_recent = true

    configuration_values = jsonencode({
      env = {
        ENABLE_PREFIX_DELEGATION = "true"
        WARM_PREFIX_TARGET      = "1"
      }
    })
    }
  }

  
  eks_managed_node_groups = {
  
    main = {
      name           = "main-nodegroup-v4"
      instance_types = [var.node_instance_type]
      capacity_type  = "ON_DEMAND"

      ami_type = "AL2023_x86_64_STANDARD"

      min_size     = 3
      max_size     = 5
      desired_size = 3

      # Configuración de disco
      disk_size = 20

      # Labels para los pods
      labels = {
        Environment = var.environment
        NodeGroup   = "main"
      }


      update_config = {
        max_unavailable_percentage = 50
      }
    }


  }

  tags = {
    Environment = var.environment
    Region      = "us-east-2"
  }

}







