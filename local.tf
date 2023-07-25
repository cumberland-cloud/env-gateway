locals {
    # constants
    domain                                  = "cumberland-cloud.com"
    lambda_prefix                           = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.acocunt_id}:function"
    metadata_keys                           = [ "ecrs", "root" ]
    tenant_access_group_name                = "${local.namespace.root}-tenant-access"
    # master configuration
    #   NOTES:
    #       1. The image specifed in an endpoint configuration must be defined in the `ecrs` property
    #           of that namespace's branch.
    namespaces                              = {
        root                                = "cumberland-cloud"
        tenant                              = {
            root                            = "tenant"
            ecrs                            = [
                "get-sale",
                "get-inventory",
                "post-inventory",
                "post-sale"
            ]
            cafe_mark                       = {
                root                        = "cafe-mark"
                endpoints                   = [{
                    authorization           = "TODO"
                    image                   = "get-sale"
                    method                  = "GET"
                    environment             = { }
                },{
                    authorization           = "NONE"
                    image                   = "get-inventory"
                    method                  = "GET"
                    environment             = { }
                },{
                    authorization           = "TODO"
                    image                   = "post-sale"
                    method                  = "POST"
                    environment             = { }
                },{
                    authorization           = "TODO"
                    image                   = "post-inventory"
                    method                  = "POST"
                    environment             = { }
                }]
            }
            sunshine_daze                   = {
                root                        = "sunshine-daze"
                endpoints                   = [{
                    authorization           = "TODO"
                    image                   = "get-sale"
                    method                  = "GET"
                    environment             = { }
                },{
                    authorization           = "NONE"
                    image                   = "get-inventory"
                    method                  = "GET"
                    environment             = { }
                },{
                    authorization           = "TODO"
                    image                   = "post-sale"
                    method                  = "POST"
                    environment             = { }
                },{
                    authorization           = "TODO"
                    image                   = "post-inventory"
                    method                  = "POST"
                    environment             = { }
                }]
            }
        }
        system                              = {
            root                            = "system"
            auth                            = {
                root                        = "auth"
                ecrs                        = [
                    "authorize",
                    "login",
                    "register"
                ]
                endpoints                   = [{
                    authorization           = "TODO"
                    image                   = "authorize"
                    method                  = "GET"
                    environment             = {
                        ACCOUNT_ID          = data.aws_caller_identity.current.account_id
                        API_ID              = aws_api_gateway_rest_api.this.id
                        CLIENT_ID           = module.cognito.user_pool.client_id
                        GROUP               = "TODO"
                        USERPOOL_ID         = module.cognito.user_pool.id
                        REGION              = data.aws_region.current.name
                    }
                },{
                    authorization           = "NONE"
                    image                   = "token"
                    method                  = "POST"
                    environment             = {
                        CLIENT_ID           = "TODO"
                    }
                },{
                    authorization           = "NONE"
                    image                   = "register"
                    method                  = "POST"
                    environment             = {
                        CLIENT_ID           = "TODO"
                    }
                }]
            }
        }
    }
    # intermediate calculations
    tenant_endpoints                = flatten([ 
        for key, tenant in local.namespaces.tenant:[
            for endpoint in tenant.endpoints: {
                image               = "${local.namespaces.root}/${local.namespaces.tenant.root}/${endpoint.image}"
                environment         = endpoint.environment
                method              = endpoint.method
                path                = "/${local.namespaces.root}/${local.namespaces.tenant.root}/${tenant.root}/${endpoint.image}"
                parent_id           = aws_api_gateway_resource.tenants[tenant.root].id
                type                = "tenant"
                type_key            = key
            }
        ] if !contains(local.metadata_keys, key)
    ])
    system_endpoints                = flatten([ 
        for key, system in local.namespaces.sytem:[
            for endpoint in system.endpoints: {
                environment         = endpoinT.environment
                image               = "${local.namespaces.root}/${local.namespaces.system.root}/${system.root}/${endpoint.image}"
                method              = endpoint.method
                path                = "/${local.namespaces.root}/${local.namespaces.system.root}/${system.root}/${endpoint.image}"
                parent_id           = aws_api_gateway_resource.systems[system.root].id
                type                = "system"
                type_key            = key
            }
        ] if !contains(local.metadata_keys, key)
    ])
    # final
    ecrs                            = concat([ 
        for ecr in local.namespaces.tenant.ecrs: 
            "${local.namespaces.root}/${local.namespaces.tenant.root}/${ecr}"
    ],[
        for ecr in local.namespace.system.auth.ecrs:
            "${local.namespaces.root}/${local.namespaces.system.root}/${local.namespaces.system.auth.root}/${ecr}"
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
}