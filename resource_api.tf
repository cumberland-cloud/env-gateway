resource "aws_cloudwatch_log_group" "this" {
    #checkov:skip=CKV_AWS_338: "Ensure CloudWatch log groups retains logs for at least 1 year"
        # NOTE: checkov's a golddigger
    kms_key_id                  = module.kms.key.arn
    name                        = "/aws/apigateway/${local.root_namespace}-api-gateway"
    retention_in_days           = 14
}

resource "aws_api_gateway_account" "this" {
    cloudwatch_role_arn         = module.iam.service_roles["api_gateway"].arn
}

resource "aws_api_gateway_rest_api" "this" {
    name                        = "${local.root_namespace}-api-gateway"

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
    #checkov:skip=CKV2_AWS_29: "Ensure public API gateway are protected by WAF"

    cache_cluster_enabled       = true
    cache_cluster_size          = 13.5
    client_certificate_id       = aws_api_gateway_client_certificate.this.id
    deployment_id               = aws_api_gateway_deployment.this.id
    rest_api_id                 = aws_api_gateway_rest_api.this.id
    stage_name                  = "production"
    xray_tracing_enabled        = true

    access_log_settings {
        destination_arn         = aws_cloudwatch_log_group.this.arn
        format                  = "json"
   }
}

resource "aws_api_gateway_method_settings" "this" {
    rest_api_id                 = aws_api_gateway_rest_api.this.id
    stage_name                  = aws_api_gateway_stage.this.stage_name
    method_path                 = "*/*"

    settings {
        caching_enabled         = true
        cache_ttl_in_seconds    = 300
        cache_data_encrypted    = true
        metrics_enabled         = true
        logging_level           = "INFO"
    }
}

resource "aws_api_gateway_authorizer" "this" {
    authorizer_uri              = local.authorize_lambda_invoke_arn
    name                        = "${local.root_namespace}-api-authorizer"
    identity_source             = "method.request.header.authorization"
    rest_api_id                 = aws_api_gateway_rest_api.this.id
    type                        = "TOKEN"
}

resource "aws_api_gateway_request_validator" "this" {
  name                          = "${local.root_namespace}-request-validator"
  rest_api_id                   = aws_api_gateway_rest_api.this.id
  validate_request_body         = true
  validate_request_parameters   = true
}

resource "aws_api_gateway_resource" "root" {
    parent_id                   = aws_api_gateway_rest_api.this.root_resource_id
    path_part                   = "gateway"
    rest_api_id                 = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_resource" "namespaces" {
    for_each                    = local.cumberland_cloud
            
    parent_id                   = aws_api_gateway_resource.root.id
    path_part                   = replace(each.key, "_", "-")
    rest_api_id                 = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_resource" "subspaces" {
    for_each                    = "TODO"

    parent_id                   = aws_api_gateway_resource.namespaces[each.value.namespace].id
    path_path                   = replace(each.key, "_", "-")
    rest_api_id                 = aws_api_gateway_rest_api.this.id
}

# this only gives gateway/system and gateway/tenant
# needs another layer for auth and cafe-mark//sunshine-daze