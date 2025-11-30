provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  availability_zones   = ["us-west-1a", "us-west-1b"]
}

module "security_groups" {
  source = "./modules/security_groups"
  vpc_id = module.vpc.vpc_id
}

module "load_balancer" {
  source         = "./modules/load_balancer"
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnet_ids
  web_sg_id      = module.security_groups.web_sg_id
}

module "web_tier" {
  source              = "./modules/web_tier"
  vpc_id              = module.vpc.vpc_id
  public_subnets      = module.vpc.public_subnet_ids
  web_sg_id           = module.security_groups.web_sg_id
  lb_target_group_arn = module.load_balancer.lb_target_group_arn
}

module "app_tier" {
  source          = "./modules/app_tier"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnet_ids
  app_sg_id       = module.security_groups.app_sg_id
  web_sg_id       = module.security_groups.web_sg_id
  db_sg_id        = module.security_groups.db_sg_id
}

module "database_tier" {
  source               = "./modules/database_tier"
  db_sg_id             = module.security_groups.db_sg_id
  db_subnet_group_name = module.vpc.db_subnet_group_name
  db_password          = "YourSecurePassword123" # Change this!
}

# Add this to your root configuration

terraform {
  backend "s3" {
    bucket         = "my-3-tier-app-tfstate" # The S3 bucket you created
    key            = "global/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
  }
}
