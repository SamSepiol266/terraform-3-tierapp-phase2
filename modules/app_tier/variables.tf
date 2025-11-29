variable "vpc_id" { type = string }
variable "private_subnets" { type = list(string) }
variable "app_sg_id" { type = string }
variable "web_sg_id" { type = string }
variable "db_sg_id" { type = string }
