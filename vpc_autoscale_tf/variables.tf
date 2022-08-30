/*
Process to change image for a software roll out:
current = set to the next value 1 or 0
image_name_0 and image_name_1 = change the new current one appropriately.  Keep the other one the same

these are set in apply.sh and destroy.sh
*/
variable "current" {}
variable "image_name_0" {}
variable "image_name_1" {}

variable "ibmcloud_timeout" {
  description = "Timeout for API operations in seconds."
  default     = 900
}

variable "resource_group_name" {
  description = "Your resource group name"
}

variable "prefix" {
  description = "Prefix used for all resource names"
}

variable "region" {
  description = "The region in which you want to provision your VPC and its resources"
}

variable "ssh_key_name" {
  description = "Name of the SSH key to use"
}

variable "certificate_crn" {
  description = "certificate instance CRN if you wish SSL offloading or End-to-end encryption"
  type        = string
  default     = ""
}

variable "enable_end_to_end_encryption" {
  description = "Set it to true if you wish to enable End-to-end encryption"
  type        = bool
  default     = false
}