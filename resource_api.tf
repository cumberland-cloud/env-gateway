resource "aws_api_gateway_account" "this" {
    cloudwatch_role_arn         = module.iam.service_roles["api_gateway"].arn
}

resource "aws_api_gateway_rest_api" "this" {
    name                        = "${local.namespace.root}-api-gateway"

    lifecycle {
        create_before_destroy   = true
    }
}

resource "aws_api_gateway_deployment" "this" {
    rest_api_id                 = aws_api_gateway_rest_api.this.id
    triggers                    = {
        redeployment            = local.redeploy_hash
    }

    lifecycle {
        create_before_destroy   = true
    }
}

resource "aws_api_gateway_stage" "this" {
    deployment_id               = aws_api_gateway_deployment.this.id
    rest_api_id                 = aws_api_gateway_rest_api.this.id
    stage_name                  = "production"
}

resource "aws_api_gateway_method_settings" "this" {
    rest_api_id                 = aws_api_gateway_rest_api.this.id
    stage_name                  = aws_api_gateway_stage.this.stage_name
    method_path                 = "*/*"

    settings {
        metrics_enabled         = true
        logging_level           = "INFO"
    }
}

resource "aws_api_gateway_authorizer" "this" {
    authorizer_uri              = module.lambda[local.authorize_lambda_index].invoke_arn
    name                        = "${local.namespaces.root}-api-authorizer"
    identity_source             = "method.request.header.authorization"
    rest_api_id                 = aws_api_gateway_rest_api.this.id
    type                        = "TOKEN"
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

# TODO: Cors methods