locals {
    # constants
    domain                                  = "cumberland-cloud.com"
    lambda_prefix                           = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.acocunt_id}:function"
    metadata_keys                           = [ "ecrs", "namespace" ]
    project_title                           = title(replace(local.namespaces.namespace, "-", " "))
    tenant_access_group_name                = "${local.namespace.namespace}-tenant-access"
    # intermediate calculations
    tenant_endpoints                = flatten([ 
        for key, tenant in local.namespaces.tenant:[
            for endpoint in tenant.endpoints: {
                image               = "${local.namespaces.namespace}/${local.namespaces.tenant.namespace}/${endpoint.image}"
                environment         = endpoint.environment
                method              = endpoint.method
                path                = "/${local.namespaces.namespace}/${local.namespaces.tenant.namespace}/${tenant.namespace}/${endpoint.image}"
                parent_id           = aws_api_gateway_resource.tenants[tenant.namespace].id
                type                = "tenant"
                type_key            = key
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
                parent_id           = aws_api_gateway_resource.systems[system.namespace].id
                type                = "system"
                type_key            = key
            }
        ] if !contains(local.metadata_keys, key)
    ])
    # pre deployment locals
    ecrs                            = concat([ 
        for ecr in local.namespaces.tenant.ecrs: 
            "${local.namespaces.namespace}/${local.namespaces.tenant.namespace}/${ecr}"
    ],[
        for ecr in local.namespace.system.auth.ecrs:
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
    authorize_lambda_index          = keys({ 
        for k,v in local.endpoints: 
            k                       => v 
            if v.type == "system" 
                && v.type_key == "auth" 
                && strcontains(v.image, "authorize")
    })[0]
    redeploy_hash                  = sha1(jsonencode(aws_api_gateway_rest_api.example.body))
}