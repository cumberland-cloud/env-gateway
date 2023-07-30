locals {
    # master configuration
    #   NOTES:
    #       1. The image specifed in an endpoint configuration must be defined in the `ecrs` property
    #           of that namespace's branch.
    namespaces                              = {
        namespace                           = "cumberland-cloud"
        tenant                              = {
            namespace                       = "tenant"
            ecrs                            = [ "get-inventory", "get-sale", "post-inventory", "post-sale" ]
            cafe_mark                       = {
                namespace                   = "cafe-mark"
                endpoints                   = [{
                    authorization           = aws_api_gateway_authorizer.this.id
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
                    authorization           = aws_api_gateway_authorizer.this.id
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
                    authorization           = aws_api_gateway_authorizer.this.id
                    image                   = "post-inventory"
                    method                  = "POST"
                    environment             = { 
                        TENANT              = "cafe-mark"
                    }
                    request_model           = {
                        type                = "object"
                        required            = [ "tenant_id", "inventory_id", "quantity"]
                        properties          = {
                            description     = {
                                type        = "string"
                            }
                            image_path      = {
                                type        = "string"
                            }
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
                }]
            }
            sunshine_daze                   = {
                namespace                   = "sunshine-daze"
                endpoints                   = [{
                    authorization           = aws_api_gateway_authorizer.this.id
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
                    authorization           = aws_api_gateway_authorizer.this.id
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
                    authorization           = aws_api_gateway_authorizer.this.id
                    image                   = "post-inventory"
                    method                  = "POST"
                    environment             = { 
                        TENANT              = "sunshine-daze"
                    }
                    request_model           = {
                        type                = "object"
                        required            = [ "tenant_id", "inventory_id", "quantity"]
                        properties          = {
                            description     = {
                                type        = "string"
                            }
                            image_path      = {
                                type        = "string"
                            }
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
                }]
            }
        }
        system                              = {
            namespace                       = "system"
            auth                            = {
                namespace                   = "auth"
                ecrs                        = [ "authorize", "token", "register" ]
                endpoints                   = [{
                    authorization           = aws_api_gateway_authorizer.this.id
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
                        CLIENT_ID           = module.cognito.user_pool.client_id
                    }
                    request_model           = {
                        type                = "object"
                        required            = [ "tenant_id", "inventory_id", "quantity"]
                        properties          = {
                            username        = {
                                type        = "string"
                            }
                            password        = {
                                type        = "string"
                            }
                        }
                    }
                },{
                    authorization           = "NONE"
                    image                   = "register"
                    method                  = "POST"
                    environment             = {
                        CLIENT_ID           = module.cognito.user_pool.client_id
                    }
                    request_model           = {
                        type                = "object"
                        required            = [ "tenant_id", "inventory_id", "quantity"]
                        properties          = {
                            username        = {
                                type        = "string"
                            }
                            password        = {
                                type        = "string"
                            }
                            first_name      = {
                                type        = "string"
                            }
                            last_name       = {
                                type        = "string"
                            }
                            email           = {
                                type        = "string"
                            }
                        }
                    }
                }]
            }
        }
    }
}