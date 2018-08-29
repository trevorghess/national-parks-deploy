variable "azure_region" {
  default = "eastus"
}

variable "azure_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "azure_private_key_path" {
  default = "~/.ssh/id_rsa"
}

variable "azure_image_user" {
  default = "azureuser"
}

variable "azure_image_password" {
  default = "Azur3pa$$word"
}

variable "azure_sub_id" {
  default = "e6b872d2-4d5a-42aa-9ac9-8f5e03f556dc"
}

variable "azure_tenant_id" {
  default = "a2b2d6bc-afe1-4696-9c37-f97a7ac416d7"
}

variable "application" {
  default = "nationalparks"
}

variable "habitat_origin" {
  default = "th_demo"
}

variable "bldr_url" {
  default = "https://bldr.habitat.sh"
}

variable "release_channel" {
  default = "stable"
}

variable "group" {
  default = "dev"
}

variable "update_strategy" {
  default = "at-once"
}

variable "application_port" {
  description = "The port that you want to expose to the external load balancer"
  default     = 8080
}

variable "lb_application_port" {
  description = "The port that you want to expose to the external load balancer"
  default     = 80
}

variable "vmss_capacity" {
  description = "How many VMs should be in your scale set"
  default     = 20
}

variable "automate_server" {
  description = "the url for your automate server"
  default = ""
}

variable "validation_key" {
  description = "validation key for bootstrapping"
  default = ""
}