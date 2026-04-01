# Get current AWS account ID for Lambda permissions
data "aws_caller_identity" "current" {}

locals {
  integrations = {
    for item in flatten([
      for api_key, api in var.api_gtws : [
        for int_key, int in api.integrations : {
          key   = int_key
          value = merge(
            { api_id = module.api_definitions[api_key].api_id },
            int,
            # Resolve lambda_key to invoke ARN if lambda_key is provided
            int.lambda_key != null ? {
              integration_uri = module.lambda[int.lambda_key].lambda_function_invoke_arn
            } : {}
          )
        }
      ]
    ]) : item.key => item.value
  }
  routes = {
    for item in flatten([
      for api_key, api in var.api_gtws : [
        for r_key, r in api.routes : {
          key   = r_key
          value = merge({ api_id = module.api_definitions[api_key].api_id }, r)
        }
      ]
    ]) : item.key => item.value
  }
  stages = {
    for item in flatten([
      for api_key, api in var.api_gtws : [
        for s_key, s in api.stages : {
          key   = s_key
          value = merge({ api_id = module.api_definitions[api_key].api_id }, s)
        }
      ]
    ]) : item.key => item.value
  }
  
  # Lambda permissions for API Gateway
  # Extract unique Lambda functions that need permissions
  lambda_integrations = {
    for item in flatten([
      for api_key, api in var.api_gtws : [
        for int_key, int in api.integrations : 
          int.lambda_key != null ? {
            lambda_key = int.lambda_key
            api_key    = api_key
          } : null
      ]
    ]) : item.lambda_key => item if item != null
  }
}

module "api_definitions" {
  for_each = var.api_gtws
  source   = "../modules/api-gatewayv2-api"
  
  depends_on = [module.lambda]

  name             = each.value.name
  protocol_type    = each.value.protocol_type
  description      = each.value.description
  
  # Required tagging variables
  environment      = var.environment
  applicationname  = var.applicationname
  applicationid    = var.applicationid
  specifictags     = {}
}

module "api_integrations" {
  for_each = local.integrations
  source   = "../modules/api-gatewayv2-integration"
  
  depends_on = [module.lambda, module.api_definitions]

  api_id                 = each.value.api_id
  integration_type       = each.value.integration_type
  integration_uri        = each.value.integration_uri
  payload_format_version = each.value.payload_format_version
  timeout_milliseconds   = each.value.timeout_milliseconds
  description            = each.value.description
}

module "api_routes" {
  for_each = local.routes
  source   = "../modules/api-gatewayv2-route"
  
  depends_on = [module.api_integrations]

  api_id             = each.value.api_id
  route_key          = each.value.route_key
  target             = "integrations/${module.api_integrations[each.value.integration_key].id}"
  authorization_type = each.value.authorization_type
}

module "api_stages" {
  for_each = local.stages
  source   = "../modules/api-gatewayv2-stage"
  
  depends_on = [module.api_routes]

  api_id      = each.value.api_id
  name        = each.value.name
  description = each.value.description
  auto_deploy = each.value.auto_deploy
  
  # Required tagging variables
  environment      = var.environment
  applicationname  = var.applicationname
  applicationid    = var.applicationid
  specifictags     = {}
}

# -----------------------------------------------------------------------------
# Lambda Permissions for API Gateway
# -----------------------------------------------------------------------------
# Allow API Gateway to invoke Lambda functions
module "api_gateway_lambda_permissions" {
  for_each = local.lambda_integrations
  source   = "../modules/lambda-permission"
  
  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda[each.key].lambda_function_name
  principal     = "apigateway.amazonaws.com"
  
  # Allow any stage/route of this API to invoke Lambda (execute-api ARN, not control plane)
  # Format: arn:aws:execute-api:region:account-id:api-id/stage/method/path
  # Wildcard: arn:aws:execute-api:region:account-id:api-id/*/*/*
  source_arn = "arn:aws:execute-api:eu-west-1:${data.aws_caller_identity.current.account_id}:${module.api_definitions[each.value.api_key].api_id}/*/*/*"
  
  # Not using function URL auth
  function_url_auth_type = null
}