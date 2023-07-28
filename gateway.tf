resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn           = module.iam.service_roles["api_gateway"].arn
}

resource "aws_api_gateway_rest_api" "this" {
    name                        = "${local.namespace.root}-gateway"

    lifecycle {
        create_before_destroy   = true
    }

}

resource "aws_api_gateway_request_validator" "this" {
  name                          = "${local.namespace.root}-request-validator"
  rest_api_id                   = aws_api_gateway_rest_api.this.id
  validate_request_body         = true
  validate_request_parameters   = true
}

resource "aws_api_gateway_resource" "root" {
    parent_id                   = aws_api_gateway_rest_api.this.root_resource_id
    path_part                   = "gateway"
    rest_api_id                 = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_resource" "tenants" {
    for_each                    = { 
        for k,v in local.namespaces.tenant:
            k                   => v if !contains(local.metadata_keys, k)                        
    }

    parent_id                   = each.parent_id
    path_part                   = each.value.root
    rest_api_id                 = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_resource" "system" {
    for_each                    = { 
        for k,v in local.namespaces.system:
            k                   => v if !contains(local.metadata_keys, k)                        
    }

    parent_id                   = each.parent_id
    path_part                   = each.value.root
    rest_api_id                 = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_resource" "endpoints" {
    for_each                    = local.endpoints

    parent_id                   = each.parent_id
    path_part                   = each.value.root
    rest_api_id                 = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_method" "endpoints" {
    for_each                    = local.endpoints

    authorization               = each.value.authorization
    http_method                 = each.value.method
    resource_id                 = aws_api_gateway_resource.endpoints[each.key].id
    rest_api_id                 = aws_api_gateway_rest_api.this.id
    request_validator_id        = aws_api_gateway_request_validator.this.id
    request_models              = {
        "application/json"      = try(aws_api_gateway_model.endpoints[each.value].name, "Empty")
    }
}

resource "aws_api_gateway_integration" "endpoints" {
    for_each                    = local.endpoints
    
    http_method                 = aws_api_gateway_method.endpoints[each.key].http_method
    resource_id                 = aws_api_gateway_resource.endpoints[each.key].id
    rest_api_id                 = aws_api_gateway_rest_api.this.id
    integration_http_method     = "POST"
    type                        = "AWS_PROXY"
    uri                         = module.lambda[each.key].invoke_arn
}

resource "aws_api_gateway_model" "endpoints" {
    for_each                    = { 
        for k,v in local.endpoints:
            k                   => v if try(v.request_model, null) != null
    }

    rest_api_id                 = aws_api_gateway_rest_api.this.id
    name                        = "${each.value.image}-model"
    description                 = "a JSON schema for ${each.value.image} endpoints"
    content_type                = "application/json"
    schema                      = jsonencode(each.value.request_model)
}

# TODO: Cors methods