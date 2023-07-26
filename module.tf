module "iam" {
    source              = "git::https://github.com/cumberland-cloud/modules-iam.git?ref=master"

    namespace           = local.namespaces.root
}

module "kms" {
  source                = "https://github.com/cumberland-cloud/modules-kms.git?ref=master"

  key                   = {
    alias               = local.namespaces.root
  }
}

module "cognito" {
    source              = "git::https://github.com/cumberland-cloud/modules-cognito.git?ref=master"

    cognito             = {
        user_pool_name  = local.namespaces.root
        access_group    = {
            name        = local.tenant_access_group_name
            role_arn    = module.iam.tenant_role.arn
        }
    }
    domain              = local.domain
}

module "ecr" {
    depends_on          = [ module.kms ]
    for_each            = local.ecrs
    source              = "git::https://github.com/cumberland-cloud/modules-ecr.git?ref=master"

    repository          = {
        kms_key_arn     = module.kms.key.arn
        name            = each.value.name
        namespace       = "${local.namespaces.root}/${each.value.namespace}"
        policy          = data.aws_iam_policy_document.lambda_ecr_access[each.key].json
    }
}

module "lambda" {
    depends_on          = [ 
        module.cognito,
        module.ecr, 
        module.kms,
        module.iam 
    ]
    for_each            = local.endpoints
    source              = "git::https://github.com/cumberland-cloud/modules-lambda.git?ref=master"

    lambda              = {
        function_name   = each.value.path
        execution_role  = module.iam.service_roles["lambda"]
        image_url       = each.value.image
        kms_key_arn     = module.kms.key.arn
    }
}