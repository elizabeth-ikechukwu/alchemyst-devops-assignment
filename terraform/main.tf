terraform {
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

module "networking" {
  source = "./modules/networking"

  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  availability_zone   = var.availability_zone
}

module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
  vpc_cidr     = var.vpc_cidr
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}

module "compute" {
  source = "./modules/compute"

  project_name        = var.project_name
  public_subnet_id    = module.networking.public_subnet_id
  private_subnet_id   = module.networking.private_subnet_id
  public_sg_id        = module.security_groups.public_sg_id
  private_sg_id       = module.security_groups.private_sg_id
  vm1_instance_type   = var.vm1_instance_type
  vm2_instance_type   = var.vm2_instance_type
  vm3_instance_type   = var.vm3_instance_type
  engine_repo_url     = module.ecr.engine_repo_url
  caller_repo_url     = module.ecr.caller_worker_repo_url
  inference_repo_url  = module.ecr.inference_worker_repo_url
}