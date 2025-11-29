variable "vpc_id" { type = string }
variable "public_subnets" { type = list(string) }
variable "web_sg_id" { type = string }
variable "lb_target_group_arn" { type = string }
