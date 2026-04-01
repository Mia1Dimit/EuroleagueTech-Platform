locals {
  iam_policies = {
    for item in flatten([
      for ps_key, ps in var.iam_roles : [
        for p_key, pol in ps.policies : {
          key = "${ps_key}_${p_key}"  # Unique key: vendors-api-role_dynamodb-read
          value = {
            role_id = module.aws-iam-role[ps_key].iam_role_id
            name    = pol.name
            policy  = pol.policy
          }
        }
      ]
    ]) : item.key => item.value
  }
}

module "aws-iam-role" {
  for_each = var.iam_roles
  source   = "../modules/iam-role"

  name               = each.value["name"]
  assume_role_policy = file("${path.module}/data/iam_role_policies/${each.value["assume_role_policy"]}")

  specifictags     = each.value["specifictags"]
  applicationname  = var.applicationname
  applicationid    = var.applicationid
  environment      = var.environment
}

module "aws-iam-role-policy" {
  for_each = local.iam_policies
  source   = "../modules/iam-role-policy"

  name   = each.value["name"]
  role   = each.value["role_id"]
  policy = file("${path.module}/data/iam_role_policies/${each.value["policy"]}")
}