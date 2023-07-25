resource "aws_api_gateway_account" "demo" {
  cloudwatch_role_arn       = module.iam.service_roles["api_gateway"].arn
}

resource "aws_api_gateway_rest_api" "this" {
    name                    = "${local.namespace.root}-gateway"
}

resource "aws_api_gateway_resource" "root" {
    parent_id               = aws_api_gateway_rest_api.this.root_resource_id
    path_part               = "gateway"
    rest_api_id             = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_resource" "tenants" {
    for_each                = { 
        for k,v in local.namespaces.tenant:
            k               => v if !contains(local.metadata_keys, key)                        
    }

    parent_id               = each.parent_id
    path_part               = each.value.root
    rest_api_id             = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_resource" "system" {
    for_each                = { 
        for k,v in local.namespaces.system:
            k               => v if !contains(local.metadata_keys, key)                        
    }

    parent_id               = each.parent_id
    path_part               = each.value.root
    rest_api_id             = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_resource" "endpoints" {
    for_each                = local.endpoints

    parent_id               = each.parent_id
    path_part               = each.value.root
    rest_api_id             = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_method" "endpoints" {
    for_each                = local.endpoints

    authorization           = each.value.authorization
    http_method             = each.value.method
    resource_id             = aws_api_gateway_resource.endpoints[each.key].id
    rest_api_id             = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_integration" "endpoints" {
    for_each                = local.endpoints
    
    http_method             = aws_api_gateway_method.endpoints[each.key].http_method
    resource_id             = aws_api_gateway_resource.endpoints[each.key].id
    rest_api_id             = aws_api_gateway_rest_api.this.id
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = module.lambda[each.key].invoke_arn
}

# TODO