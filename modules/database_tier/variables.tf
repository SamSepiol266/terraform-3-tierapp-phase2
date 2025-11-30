variable "db_sg_id" { type = string }
variable "db_subnet_group_name" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
