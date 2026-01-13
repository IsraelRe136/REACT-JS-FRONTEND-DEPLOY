variable "cluster_name" {
  description = "Nombre del cluster EKS"
  type        = string
  default     = "ReactAppCluster2"
}

variable "cluster_version" {
  description = "Versión de Kubernetes"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Entorno de despliegue"
  type        = string
  default     = "dev"
}

variable "node_instance_type" {
  description = "Tipo de instancia para los nodos"
  type        = string
  default     = "t2.micro"
}