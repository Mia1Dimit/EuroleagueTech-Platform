variable "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  type        = string
}

variable "dashboard_body" {
  description = "Dashboard JSON body. Use jsonencode(...) from the caller for maintainability"
  type        = string
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

variable "name" {
  type        = string
  description = "Name tag for the dashboard (kept for interface consistency)"
}

variable "purpose" {
  type        = string
  description = "Purpose of the dashboard"
  default     = "Operational observability"
}

variable "specifictags" {
  type        = map(string)
  description = "Specific tags for consistency with repository module interface"
  default     = {}
}
