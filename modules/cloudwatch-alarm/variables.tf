variable "alarm_name" {
  type = string
}

variable "alarm_description" {
  type    = string
  default = null
}

variable "metric_name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "statistic" {
  type    = string
  default = "Average"
}

variable "period" {
  type    = number
  default = 300
}

variable "evaluation_periods" {
  type    = number
  default = 1
}

variable "threshold" {
  type = number
}

variable "comparison_operator" {
  type = string
}

variable "alarm_actions" {
  type    = list(string)
  default = []
}

variable "ok_actions" {
  type    = list(string)
  default = []
}

variable "dimensions" {
  type    = map(string)
  default = {}
}

variable "treat_missing_data" {
  type    = string
  default = "missing"
}

variable "environment" {
  type = string
}

variable "applicationid" {
  type = string
}

variable "applicationname" {
  type = string
}

variable "specifictags" {
  type    = map(string)
  default = {}
}

locals {
  common_tags = {
    Application_ID   = var.applicationid
    Application_Name = var.applicationname
    Environment      = var.environment
    Name             = var.alarm_name
    Module           = "cloudwatch-alarm"
  }
  merged_tags = merge(local.common_tags, var.specifictags)
}
