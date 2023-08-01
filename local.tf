locals {
    # namespaces
        # i can't tell if this is a good idea or the worst idea i've ever had...
    root_namespace                          = keys(local.namespaces)[0]
    tenant_namespace                        = keys(local.namespaces[local.root_namespace])[0]
    tenant_namespaces                       = local.namespaces[local.root_namespace][local.tenant_namespace]
    system_namespace                        = keys(local.namespaces[local.root_namespace])[1]
    auth_namespace                          = local.namespaces[local.root_namespace][local.system_namespace][0]

    # constants
    authorize_lambda_name                   = "/${local.root_namespace}/${local.system_namespace}/${local.auth_namespace}/authorize"
    authorize_lambda_invoke_arn             = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${local.authorize_lambda_name}"
    domain                                  = "cumberland-cloud.com"
    ecrs                                    = {
        "${local.auth_namespace}"           = [ "authorize", "token", "register" ]
        "${local.tenant_namespace}"         = [ "get-inventory", "get-sale", "post-inventory", "post-sale" ]
    }
    lambda_prefix                           = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.acocunt_id}:function"
    project_title                           = title(replace(local.root_namespace, "-", " "))
    tenant_access_group_name                = "${local.root_namespace}-tenant-access"
    # calculations
    ecr_endpoint_access             = {
        for ecr in local.ecrs:
            ecr                     => [
                for index, endpoint in local.endpoints: 
                    endpoint.path if ecr == endpoint.image
            ]
    }
    endpoints                       = flatten([
        for namespace_key, namespace in local.cumberland_cloud:[
            for subspace_key, subspace in namespace: [
                for endpoint in subspace.endpoints: {
                    authorization   = endpoint.authorization
                    environment     = try(endpoint.environment, null)
                        # note: tenant images are not tenant specific, i.e. all tenants use the same images
                    image           = namespace_key == local.tenant_namespace ? (
                                        "${local.root_namespace}/${namespace_key}/${endpoint.image}"
                                    ): (
                                        "${local.root_namespace}/${namespace_key}/${subspace_key}/${endpoint.image}"
                                    )
                    method          = eachpoint.authorization
                    path            = "${local.root_namespace}/${namespace_key}/${subspace_key}/${endpoint.image}"
                    namespace       = namespace_key
                    subspace        = subspace_key
            }]
        ]
    ])
    endpoints_map                    = {
        for index, endpoint in concat(
            local.tenant_endpoints, 
            local.system_endpoints
        ): 
            index                   => endpoint
    }
    repositories                        = concat([ 
        for ecr in local.ecrs.tenant: 
            "${local.namespace.root}/${local.tenant_namespace}/${ecr}"
    ],[
        for ecr in local.ecrs.auth:
            "${local.root_namespace}/${local.system_namespace}/auth/${ecr}"
    ])
    # lambda execution environments
    system_environment              = {
        ACCOUNT_ID          = data.aws_caller_identity.current.account_id
        API_ID              = aws_api_gateway_rest_api.this.id
        CLIENT_ID           = module.cognito.user_pool.client_id
        GROUP               = "TODO"
        USERPOOL_ID         = module.cognito.user_pool.id
        REGION              = data.aws_region.current.name
    }
    # triggers
    redeploy_hash                  = sha1(jsonencode(aws_api_gateway_rest_api.this.body))
}