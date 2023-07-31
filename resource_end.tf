resource "aws_api_gateway_resource" "this" {
    for_each                    = local.endpoints

    parent_id                   = aws_api_gateway_resource.namespaces[each.value.namespace]
    path_part                   = each.value.subspace
    rest_api_id                 = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_method" "this" {
    for_each                    = local.endpoints

    authorization               = each.value.authorization ? aws_api_gateway_authorizer.this.id : "NONE" 
    http_method                 = each.value.method
    resource_id                 = aws_api_gateway_resource.endpoints[each.key].id
    rest_api_id                 = aws_api_gateway_rest_api.this.id
    request_validator_id        = aws_api_gateway_request_validator.this.id
    request_models              = {
        "application/json"      = try(aws_api_gateway_model.endpoints[each.value].name, "Empty")
    }
}

resource "aws_api_gateway_integration" "this" {
    for_each                    = local.endpoints
    
    http_method                 = aws_api_gateway_method.endpoints[each.key].http_method
    resource_id                 = aws_api_gateway_resource.endpoints[each.key].id
    rest_api_id                 = aws_api_gateway_rest_api.this.id
    integration_http_method     = "POST"
    type                        = "AWS_PROXY"
    uri                         = module.lambda[each.key].invoke_arn
}

resource "aws_lambda_permission" "this" {
    for_each                    = local.endpoints

    statement_id                = "APIGatewayLambdaInvoke"
    action                      = "lambda:InvokeFunction"
    function_name               = module.lambda[each.key].name
    principal                   = "apigateway.amazonaws.com"
    source_arn                  = "${aws_api_gateway_rest_api.this.execution_arn}/*/*/*"
}

resource "aws_api_gateway_method" "cors" {
    #checkov:skip=CKV2_AWS_53: "Ensure AWS API gateway request is validated"
    
    for_each                    = local.endpoints

    authorization               = "NONE"
    http_method                 = "OPTIONS"
}

resource "aws_api_gateway_method_response" "cors" {
    for_each                    = local.endpoints

    rest_api_id                 = aws_api_gateway_rest_api.this.id
    resource_id                 = aws_api_gateway_resource.this[each.key].id
    http_method                 = aws_api_gateway_method.cors[each.key].http_method
    response_models             = {
        "application/json"      = "Empty"
    }
    reponse_parameters          = {
        "method.response.header.Access-Control-Allow-Headers"   = false
        "method.response.header.Access-Control-Allow-Methods"   = false
        "method.response.header.Access-Control-Allow-Origin"    = false
    }
    status_code                 = "200"

}

resource "aws_api_gateway_integration" "cors" {
    for_each                    = local.endpoints

    http_method                 = aws_api_gateway_method.cors[each.key].http_method
    passthrough_behavior        = "WHEN_NO_MATCH"
    rest_api_id                 = aws_api_gateway_rest_api.this.id
    resource_id                 = aws_api_gateway_resource.this[each.key].id
    type                        = "MOCK"
}

resource "aws_api_gateway_integration_response" "cors" {
    for_each                    = local.endpoints

    rest_api_id                 = aws_api_gateway_rest_api.this.id
    resource_id                 = aws_api_gateway_resource.this[each.key].id
    http_method                 = aws_api_gateway_method.cors[each.key].http_method
    status_code                 = aws_api_gateway_method_response.cors[each.key].status_code
    response_parameters         = jsonencode({
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
        "method.response.header.Access-Control-Allow-Methods" = "'*'"
        "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    })
    response_templates          = {
        "application/json"      = jsonencode({
            status_code         = 200
        })
    }
}

resource "aws_api_gateway_model" "this" {
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