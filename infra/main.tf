# Set provider
provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "./modules/vpc"
}

module "elb" {
  source                        = "./modules/elb"
  prj_capstone_vpc_id           = module.vpc.capstone_vpc_id
  prj_capstone_sg_id            = module.vpc.capstone_security_group_id
  prj_capstone_sub_id           = module.vpc.capstone_subnet_main
  prj_capstone_sub_secondary_id = module.vpc.capstone_subnet_secondary
}

module "ecr" {
  source = "./modules/ecr"
  prj_capstone_ecr_name = var.ecr_repository_name
  prj_capstone_sg_id            = module.vpc.capstone_security_group_id
  prj_capstone_sub_id           = module.vpc.capstone_subnet_main
  prj_capstone_sub_secondary_id = module.vpc.capstone_subnet_secondary
  prj_capstone_alb_tg_arn       = module.elb.capstone_alb_tg_arn
}
