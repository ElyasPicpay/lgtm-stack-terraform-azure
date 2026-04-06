variable "name_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_address_space" {
  type = list(string)
}

variable "subnet_container_apps_cidr" {
  type = string
}

variable "subnet_private_endpoints_cidr" {
  type = string
}

variable "tags" {
  type = map(string)
}
