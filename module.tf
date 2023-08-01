module "kms" {
    #checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash"

    source              = "git::https://github.com/cumberland-cloud/modules-kms.git?ref=v1.0.0"

    key                 = {
        alias           = local.root_namespace
    }
}

module "iam" {
    #checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash"

    source                  = "git::https://github.com/cumberland-cloud/modules-iam.git?ref=v1.0.0"

    namespace               = local.root_namespace
}


module "cognito" {
    #checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash"

    source                  = "git::https://github.com/cumberland-cloud/modules-cognito.git?ref=v1.0.0"

    cognito                 = {
        user_pool_name      = local.root_namespace
        access_group        = {
            name            = local.tenant_access_group_name
        }
    }
    domain                  = local.domain
    namespace               = local.root_namespace
}

module "ecr" {
    #checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash"

    depends_on              = [ module.kms ]
    for_each                = local.ecrs
    source                  = "git::https://github.com/cumberland-cloud/modules-ecr.git?ref=v1.0.0"

    repository              = {
        key                 = module.kms.key
        name                = each.value.name
        namespace           = each.value.namespace
        policy              = data.aws_iam_policy_document.ecr_access[each.key].json
    }
}

module "lambda" {
    #checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash"
    
    depends_on                  = [ 
        module.cognito,
        module.ecr, 
        module.kms,
        module.iam 
    ]
    for_each                    = local.endpoints
    source                      = "git::https://github.com/cumberland-cloud/modules-lambda.git?ref=v1.0.0"

    lambda                      = {
        function_name           = each.value.path
        execution_role          = module.iam.service_roles["lambda"]
        environment_variables   = each.value.namespace == local.system_namespace ? (
                                    local.system_environment 
                                ) : ( 
                                    each.value.environment
                                )
        image_url               = each.value.image
        kms_key_arn             = module.kms.key.arn
    }
}