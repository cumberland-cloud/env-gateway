locals {
    # constants
    domain                                  = "cumberland-cloud.com"
    lambda_prefix                           = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.acocunt_id}:function"
    project_title                           = title(replace(local.namespaces.namespace, "-", " "))
    tenant_access_group_name                = "${local.namespace.namespace}-tenant-access"
    tenant_ecrs                             = [ "get-inventory", "get-sale", "post-inventory", "post-sale" ]
    auth_ecrs                               = [ "authorize", "token", "register" ]
    # intermediate calculations
    tenant_endpoints                = flatten([ 
        for key, tenant in local.namespaces.tenant:[
            for endpoint in tenant.endpoints: {
                image               = "${local.namespaces.namespace}/${local.namespaces.tenant.namespace}/${endpoint.image}"
                environment         = endpoint.environment
                method              = endpoint.method
                path                = "/${local.namespaces.namespace}/${local.namespaces.tenant.namespace}/${tenant.namespace}/${endpoint.image}"
                namespace           = "tenant"
                subspace            = key
            }
        ] if !contains(local.metadata_keys, key)
    ])
    system_endpoints                = flatten([ 
        for key, system in local.namespaces.system:[
            for endpoint in system.endpoints: {
                environment         = endpoint.environment
                image               = "${local.namespaces.namespace}/${local.namespaces.system.namespace}/${system.namespace}/${endpoint.image}"
                method              = endpoint.method
                path                = "/${local.namespaces.namespace}/${local.namespaces.system.namespace}/${system.namespace}/${endpoint.image}"
                namespace           = "system"
                subspace            = key
            }
        ] if !contains(local.metadata_keys, key)
    ])
    # pre deployment locals
    ecrs                            = concat([ 
        for ecr in local.tenant_ecrs: # TODO
            "${local.namespaces.namespace}/${local.namespaces.tenant.namespace}/${ecr}"
    ],[
        for ecr in local.auth_ecrs:
            "${local.namespaces.namespace}/${local.namespaces.system.namespace}/${local.namespaces.system.auth.namespace}/${ecr}"
    ])
    ecr_endpoint_access             = {
        for ecr in local.ecrs:
            ecr                     => [
                for index, endpoint in local.endpoints: 
                    endpoint.path if ecr == endpoint.image
            ]
    }
    endpoints                       = {
        for index, endpoint in concat(
            local.tenant_endpoints, 
            local.system_endpoints
        ): 
            index                   => endpoint
    }
    # post deployment locals
    authorize_lambda_name           = "/${local.namespaces.namespace}/${local.namespaces.system.namespace}/${system.namespace}/authorize"
    authorize_lambda_invoke_arn     = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${local.authorize_lambda_name}"
    redeploy_hash                  = sha1(jsonencode(aws_api_gateway_rest_api.this.body))
}