provider "aws" {
  region = var.region
}

module "vpc" {
  source    = "./vpc"
  vpc_cidr  = var.vpc_cidr
}

module "subnet" {
  source              = "./subnet"
  vpc_id              = module.vpc.vpc_id
  igw_id              = module.vpc.igw_id
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
}

module "ec2" {
  source        = "./ec2"
  subnet_id     = module.subnet.public_subnet_id
  instance_type = var.instance_type
  ami           = var.ami
  key_name      = var.key_name
}

