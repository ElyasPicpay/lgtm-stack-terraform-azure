variable "name_prefix" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "storage_tier" { type = string }
variable "storage_replication_type" { type = string }
variable "subnet_private_endpoints_id" { type = string }
variable "vnet_id" { type = string }
variable "tags" { type = map(string) }
