# Módulo VPC para us-east-2
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  # AZs específicas de us-east-2
  azs = ["us-east-2a", "us-east-2b", "us-east-2c"]
  
  # Subnets privadas
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  
  # Subnets públicas
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # Habilitar NAT Gateway para las subnets privadas
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Tags requeridos por EKS
  public_subnet_tags = {
    "kubernetes.io/role/elb"              = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"     = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# Módulo EKS
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.15"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Configuración de red
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  # Endpoint del cluster (puede ser público o privado)
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # IAM Role para el cluster
  cluster_service_ipv4_cidr = "172.20.0.0/16"
  
  # Addons del cluster
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  # Node Groups administrados por EKS
  eks_managed_node_groups = {
    # Node group principal
    main = {
      name           = "main-nodegroup"
      instance_types = [var.node_instance_type]
      capacity_type  = "ON_DEMAND"

      ami_type = "AL2023_x86_64_STANDARD"

      min_size     = 2
      max_size     = 5
      desired_size = 2

      # Configuración de disco
      disk_size = 20

      # Labels para los pods
      labels = {
        Environment = var.environment
        NodeGroup   = "main"
      }

      # Taints opcionales
      # taints = [
      #   {
      #     key    = "dedicated"
      #     value  = "true"
      #     effect = "NO_SCHEDULE"
      #   }
      # ]

      # Update configuration
      update_config = {
        max_unavailable_percentage = 50
      }
    }

    # Node group para workloads específicos (opcional)
    # spot = {
    #   name           = "spot-nodegroup"
    #   instance_types = ["t3.medium", "t3.large"]
    #   capacity_type  = "SPOT"
    #
    #   min_size     = 1
    #   max_size     = 3
    #   desired_size = 1
    #
    #   disk_size = 20
    #
    #   labels = {
    #     Environment = var.environment
    #     NodeGroup   = "spot"
    #   }
    # }
  }

  tags = {
    Environment = var.environment
    Region      = "us-east-2"
  }
}

# Security Group adicional para acceso (opcional)
# resource "aws_security_group" "additional_cluster_access" {
#   name_prefix = "${var.cluster_name}-additional-access"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # Restringe esto en producción!
#   }

#   tags = {
#     Name = "${var.cluster_name}-additional-access"
#   }
# }



# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "~> 5.0"

#   name = "eks-vpc"
#   cidr = "10.0.0.0/16"

#   azs             = ["us-east-2a", "us-east-2b"]
#   public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
#   private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

#   enable_nat_gateway = true
#   single_nat_gateway = true

#   tags = {
#     Terraform   = "true"
#     Environment = "dev"
#   }
# }



# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 20.0" # Use a compatible version

#   # Use the correct parameter name for cluster name
#   name           = "primuslearning"


#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.private_subnets

#   enable_cluster_creator_admin_permissions = true

#   # Access Entries configuration
#   access_entries = {
#     israel = {
#       principal_arn = "arn:aws:iam::954976288182:user/israel"
#       policy_associations = {
#         admin = {
#           policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#           access_scope = {
#             type = "cluster"
#           }
#         }
#       }
#     }
#   }

#   # Node group configuration
#   eks_managed_node_groups = {
#     default = {
#       instance_types = ["t2.micro"]
#       min_size     = 1
#       max_size     = 3
#       desired_size = 2
#     }
#   }
# }


