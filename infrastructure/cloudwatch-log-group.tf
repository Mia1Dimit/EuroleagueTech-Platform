module "cloudwatch_log_group" {
  for_each = var.cloudwatch_log_groups
  source   = "../modules/cloudwatch-log-group"

  name              = each.value["name"]
  retention_in_days = each.value["retention_in_days"]

  specifictags     = each.value["specifictags"]
  applicationname  = var.applicationname
  applicationid    = var.applicationid
  environment      = var.environment
}