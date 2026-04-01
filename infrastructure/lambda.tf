module "lambda" {
  for_each = var.lambdas
  source   = "../modules/lambda-function"
  
  # Lambda configuration
  function_name = each.value["function_name"]
  handler       = each.value["handler"]
  runtime       = each.value["runtime"]
  
  # Code packaging
  source_dir  = each.value["source_dir"]
  output_path = each.value["output_path"]
  
  # IAM role (append "-role" to match IAM role key naming)
  role_arn = module.aws-iam-role["${each.key}-role"].iam_role_arn
  
  # Performance
  memory_size = each.value["memory_size"]
  timeout     = each.value["timeout"]
  
  # Optional features
  package_type          = each.value["package_type"]
  image_uri             = each.value["image_uri"]
  layers                = each.value["layers"]
  environment_variables = each.value["environment_variables"]
  vpc_config            = each.value["vpc_config"]
  
  # Tags
  specifictags     = each.value["specifictags"]
  applicationname  = var.applicationname
  applicationid    = var.applicationid
  environment      = coalesce(each.value["environment"], var.environment)
  
  depends_on = [module.cloudwatch_log_group, module.aws-iam-role]
}