variable "name" {
  description = "The name of the log group."
  type        = string
}

variable "log_group_class" {
  description = "The log group class (e.g., 'STANDARD' or 'INFREQUENT_ACCESS' or 'DELIVERY')."
  type        = string
  default     = "STANDARD"
}

variable "retention_in_days" {
  description = "The number of days to retain the log events in the specified log group."
  type        = number
  default     = 0
}

variable "specifictags" {
  type        = map(string)
  description = "Specific tags for the resource"
}

variable "environment" {
  type        = string
  description = "Environment Tag"
}

variable "applicationid" {
  type        = string
  description = "Application_ID Tag"
}

variable "applicationname" {
  type        = string
  description = "Application_Name Tag"
}

locals {
  common_tags = {
    Application_ID    = var.applicationid
    Application_Name  = var.applicationname
    Environment       = var.environment
    Name              = var.name
  }
  merged_tags = merge(local.common_tags, var.specifictags)
}

