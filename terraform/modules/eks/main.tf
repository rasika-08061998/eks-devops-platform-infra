module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id = var.vpc_id

  # Subnets used by worker nodes
  subnet_ids = var.private_subnets

  # Subnets used by the EKS control plane
  control_plane_subnet_ids = var.private_subnets

  enable_irsa = true

  enable_cluster_creator_admin_permissions = true

  # Enable both for bootstrap access
  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = true

  eks_managed_node_groups = {
    dev_nodes = {
      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 2
      desired_size = 1

      capacity_type = "ON_DEMAND"
    }
  }

  tags = {
    Environment = var.environment
    Project     = "eks-devops-platform"
  }
}


# Allow Bastion host to reach EKS API endpoint
resource "aws_security_group_rule" "bastion_to_eks_api" {
  description = "Allow bastion host to access EKS API"

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"

  security_group_id = module.eks.cluster_security_group_id
  cidr_blocks       = ["10.0.0.0/16"]   # VPC CIDR
}
