terraform {
  required_version = ">= 1.5.0"
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
  source            = "./modules/vpc"
  vpc_cidr          = var.vpc_cidr
  subnet_a_cidr     = var.subnet_a_cidr
  subnet_b_cidr     = var.subnet_b_cidr
  subnet_c_cidr     = var.subnet_c_cidr
  availability_zone = var.availability_zone
}

module "security_groups" {
  source   = "./modules/security_groups"
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr
}

module "ec2" {
  source            = "./modules/ec2"
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  key_name          = var.key_name
  subnet_a_id       = module.vpc.subnet_a_id
  subnet_b_id       = module.vpc.subnet_b_id
  subnet_c_id       = module.vpc.subnet_c_id
  security_group_id = module.security_groups.router_sg_id
}
