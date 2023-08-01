locals{
    authorize_lambda_name                   = "/${local.root_namespace}/${local.system_namespace}/${local.system_namespaces.auth}/authorize"
    authorize_lambda_invoke_arn             = "${local.lambda_prefix}:${local.authorize_lambda_name}:*"
    domain                                  = "cumberland-cloud.com"
    ecrs                                    = {
        authorize                           = {
            namespace                       = "${local.root_namespace}/${local.system_namespace}/${local.system_namespaces.auth}"
            name                            = "authorize"
        }
        token                               = {
            namespace                       = "${local.root_namespace}/${local.system_namespace}/${local.system_namespaces.auth}"
            name                            = "token"
        }
        register                            = {
            namespace                       = "${local.root_namespace}/${local.system_namespace}/${local.system_namespaces.auth}"
            name                            = "register"
        }
        get_inventory                       = {
            namespace                       = "${local.root_namespace}/${local.tenant_namespace}"
            name                            = "get-inventory"
        }
        get_sale                            = {
            namespace                       = "${local.root_namespace}/${local.tenant_namespace}"
            name                            = "get-sale"
        }
        post_inventory                      = {
            namespace                       = "${local.root_namespace}/${local.tenant_namespace}"
            name                            = "post-inventory"
        }
        post_sale                           = {
            namespace                       = "${local.root_namespace}/${local.tenant_namespace}"
            name                            = "post-sale"
        }
    }
    lambda_prefix                           = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function"
    namespace_title                         = title(replace(local.root_namespace, "-", " "))
    namespace_uppercase                     = replace(local.namespace_title, " ", "")
}