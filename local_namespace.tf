locals {    
    # namespaces
    root_namespace                          = "cumberland-cloud"
        # top level namespaces
    tenant_namespace                        = "tenant"
    system_namespace                        = "system"
        # second level namespaces
    tenant_namespaces                       = {
        cafe_mark                           = "cafe-mark" 
        sunshine_daze                       ="sunshine-daze" 
    }
    system_namespaces                       = {
        auth                                = "auth" 
    }
    # master configuration
        # note: try to keep this free of resource references, since most of the 
        #       module resources depend on this bit of configuration.
    cumberland_cloud                        = {
        tenant                              = {
            cafe_mark                       = {
                endpoints                   = [{
                    authorization           = true
                    image                   = "get-sale"
                    method                  = "GET"
                    environment             = { 
                        TENANT              = local.tenant_namespaces.cafe_mark
                    }
                },{
                    authorization           = false
                    image                   = "get-inventory"
                    method                  = "GET"
                    environment             = { 
                        TENANT              = local.tenant_namespaces.cafe_mark
                    }
                },{
                    authorization           = true
                    image                   = "post-sale"
                    method                  = "POST"
                    environment             = { 
                        TENANT              = local.tenant_namespaces.cafe_mark
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
                    authorization           = true
                    image                   = "post-inventory"
                    method                  = "POST"
                    environment             = { 
                        TENANT              = local.tenant_namespaces.cafe_mark
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
                endpoints                   = [{
                    authorization           = true
                    image                   = "get-sale"
                    method                  = "GET"
                    environment             = { 
                        TENANT              = local.tenant_namespaces.sunshine_daze
                    }
                },{
                    authorization           = false
                    image                   = "get-inventory"
                    method                  = "GET"
                    environment             = {
                        TENANT              = local.tenant_namespaces.sunshine_daze
                     }
                },{
                    authorization           = true
                    image                   = "post-sale"
                    method                  = "POST"
                    environment             = {
                        TENANT              = local.tenant_namespaces.sunshine_daze
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
                    authorization           = true
                    image                   = "post-inventory"
                    method                  = "POST"
                    environment             = { 
                        TENANT              = local.tenant_namespaces.sunshine_daze
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
            auth                            = {
                endpoints                   = [{
                    authorization           = true
                    image                   = "authorize"
                    method                  = "GET"
                },{
                    authorization           = false
                    image                   = "token"
                    method                  = "POST"
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
                    authorization           = false
                    image                   = "register"
                    method                  = "POST"
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