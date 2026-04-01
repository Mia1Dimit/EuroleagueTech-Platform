# ==============================================================================
# DynamoDB Tables
# ==============================================================================
# Pattern: terraform-core-mtr
# - for_each with map variable
# - Bracket notation for attribute access
# - Local module source
# ==============================================================================

module "dynamodb" {
  for_each = var.dynamodb_tables
  source   = "../modules/dynamodb"

  # Required
  table_name          = each.value["table_name"]
  hash_key            = each.value["hash_key"]
  range_key           = each.value["range_key"]
  environment         = var.environment
  applicationid       = var.applicationid
  applicationname     = var.applicationname
  name                = each.key  # Logical name (e.g., "main")

  # Optional (use project defaults or override in tfvars)
  billing_mode                  = lookup(each.value, "billing_mode", "PAY_PER_REQUEST")
  global_secondary_indexes      = lookup(each.value, "global_secondary_indexes", [])
  enable_point_in_time_recovery = lookup(each.value, "enable_point_in_time_recovery", false)
  enable_encryption             = lookup(each.value, "enable_encryption", true)
  stream_enabled                = lookup(each.value, "stream_enabled", false)
  purpose                       = lookup(each.value, "purpose", "NoSQL Database")
  specifictags                  = lookup(each.value, "specifictags", {})
}
