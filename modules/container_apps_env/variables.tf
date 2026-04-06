variable "name_prefix" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "subnet_id" { type = string }
variable "log_analytics_sku" { type = string }
variable "log_analytics_retention_days" { type = number }
variable "tags" { type = map(string) }
