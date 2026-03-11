terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_name = "eks-devops-vpc"
  vpc_cidr = "10.0.0.0/16"

  azs = [
    "ap-south-1a",
    "ap-south-1b"
  ]

  private_subnets = [
    "10.0.10.0/24",
    "10.0.11.0/24"
  ]

  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  environment = "dev"
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name = "python-microservice-app"
  environment     = "dev"
}

module "eks" {
  source = "../../modules/eks"

  cluster_name = "eks-devops-cluster"

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  bastion_sg_id = module.bastion.bastion_sg_id

  environment = "dev"
}

module "bastion" {
  source = "../../modules/bastion"

  public_subnet = module.vpc.public_subnets[0]
  vpc_id        = module.vpc.vpc_id
}

