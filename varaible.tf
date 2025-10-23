# Azure Authentication
variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "client_id" {
  type        = string
  description = "Azure Client (Application) ID"
}

variable "client_secret" {
  type        = string
  description = "Azure Client Secret"
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

# Resource Group & Location
variable "resource_group_name" {
  type        = string
  description = "Existing Resource Group name"
}

variable "location" {
  type        = string
  description = "Azure location for resources"
}

# VM Configuration
variable "admin_username" {
  type        = string
  description = "Admin username for all VMs"
}

variable "admin_password" {
  type        = string
  description = "Admin password for all VMs"
  sensitive   = true
}

variable "vm_size" {
  type        = string
  description = "Size of the Azure VMs"
}

variable "master_count" {
  type        = number
  description = "Number of Kubernetes master nodes"
}

variable "worker_count" {
  type        = number
  description = "Number of Kubernetes worker nodes"
}

