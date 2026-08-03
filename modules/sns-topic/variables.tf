variable "name" {
  description = "Name of the SNS topic. For FIFO topics the .fifo suffix is added automatically"
  type        = string
}

variable "display_name" {
  description = "Display name for the topic (used in SMS subscriptions)"
  type        = string
  default     = null
}

variable "fifo_topic" {
  description = "Whether to create a FIFO (first-in-first-out) topic"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enables content-based deduplication for FIFO topics"
  type        = bool
  default     = false
}

variable "archive_policy" {
  description = "Message archive policy JSON for FIFO topics"
  type        = string
  default     = null
}

variable "kms_master_key_id" {
  description = "ID of an AWS-managed or customer CMK for server-side encryption"
  type        = string
  default     = null
}

variable "delivery_policy" {
  description = "SNS delivery policy JSON"
  type        = string
  default     = null
}

variable "policy" {
  description = "Fully-formed AWS policy JSON attached inline to the topic"
  type        = string
  default     = null
}

variable "topic_policy" {
  description = "Separate topic policy JSON (via aws_sns_topic_policy). Set null to skip"
  type        = string
  default     = null
}

variable "tracing_config" {
  description = "Tracing mode: PassThrough or Active"
  type        = string
  default     = "PassThrough"

  validation {
    condition     = contains(["PassThrough", "Active"], var.tracing_config)
    error_message = "tracing_config must be PassThrough or Active."
  }
}

variable "signature_version" {
  description = "SNS signature version: 1 (SHA1) or 2 (SHA256)"
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2], var.signature_version)
    error_message = "signature_version must be 1 or 2."
  }
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

variable "purpose" {
  type        = string
  description = "Purpose of the SNS topic"
  default     = "Notification fan-out"
}

variable "specifictags" {
  type        = map(string)
  description = "Specific tags for the resource"
  default     = {}
}

locals {
  common_tags = {
    Application_ID   = var.applicationid
    Application_Name = var.applicationname
    Environment      = var.environment
    Name             = var.name
    Module           = "sns-topic"
    Purpose          = var.purpose
  }
  merged_tags = merge(local.common_tags, var.specifictags)
}
