variable "prj_capstone_ecr_name" {
  description = "Name of repository"
  type = string
}

variable "prj_capstone_sg_id" {
  type = string
  description = "Id of security group"
}

variable "prj_capstone_sub_id" {
  type = string
  description = "Id of subnet"
}

variable "prj_capstone_sub_secondary_id" {
  type = string
  description = "Id of subnet"
}

variable "prj_capstone_alb_tg_arn" {
  type = string
  description = "ARN of the alb"
}