locals {
    # constants
    domain                                  = "cumberland-cloud.com"
    lambda_prefix                           = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.acocunt_id}:function"
    metadata_keys                           = [ "ecrs", "namespace" ]
    tenant_access_group_name                = "${local.namespace.namespace}-tenant-access"
    # master configuration
    #   NOTES:
    #       1. The image specifed in an endpoint configuration must be defined in the `ecrs` property
    #           of that namespace's branch.
    namespaces                              = {
        namespace                           = "cumberland-cloud"
        tenant                              = {
            namespace                       = "tenant"
            ecrs                            = [
                "get-sale",
                "get-inventory",
                "post-inventory",
                "post-sale"
            ]
            cafe_mark                       = {
                namespace                   = "cafe-mark"
                endpoints                   = [{
                    authorization           = "TODO"
                    image                   = "get-sale"
                    method                  = "GET"
                    environment             = { 
                        TENANT              = "cafe-mark"
                    }
                },{
                    authorization           = "NONE"
                    image                   = "get-inventory"
                    method                  = "GET"
                    environment             = { 
                        TENANT              = "cafe-mark"
                    }
                },{
                    authorization           = "TODO"
                    image                   = "post-sale"
                    method                  = "POST"
                    environment             = { 
                        TENANT              = "cafe-mark"
                    }
                    request_model           = {
                        type                = "object"
                        required            = [ "tenant_id", "inventory_id", "quantity"]
                        properties          = {
                            inventory_id    = {
                                type        = "integer"
                            }
                            tenant_id       = {
                                type        = "string"
                            }
                            quantity        = {
                                type        = "integer"
                            }
                        }
                    }
                },{
                    authorization           = "TODO"
                    image                   = "post-inventory"
                    method                  = "POST"
                    environment             = { 
                        TENANT              = "cafe-mark"
                    }
                }]
            }
            sunshine_daze                   = {
                namespace                   = "sunshine-daze"
                endpoints                   = [{
                    authorization           = "TODO"
                    image                   = "get-sale"
                    method                  = "GET"
                    environment             = { 
                        TENANT              = "sunshine-daze"
                    }
                },{
                    authorization           = "NONE"
                    image                   = "get-inventory"
                    method                  = "GET"
                    environment             = {
                        TENANT              = "sunshine-daze"
                     }
                },{
                    authorization           = "TODO"
                    image                   = "post-sale"
                    method                  = "POST"
                    environment             = {
                        TENANT              = "sunshine-daze"
                    }
                    request_model           = {
                        type                = "object"
                        required            = [ "tenant_id", "inventory_id", "quantity"]
                        properties          = {
                            inventory_id    = {
                                type        = "integer"
                            }
                            tenant_id       = {
                                type        = "string"
                            }
                            quantity        = {
                                type        = "integer"
                            }
                        }
                    }
                },{
                    authorization           = "TODO"
                    image                   = "post-inventory"
                    method                  = "POST"
                    environment             = { 
                        TENANT              = "sunshine-daze"
                    }
                }]
            }
        }
        system                              = {
            namespace                       = "system"
            auth                            = {
                namespace                   = "auth"
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