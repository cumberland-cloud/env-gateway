# TODO: use git sources and lock with version refs.

module "iam" {
    source              = "../modules/iam"
}

module "kms" {
  source                = "../modules/kms"

  key                   = {
    alias               = local.namespace
  }
}

module "cognito" {
    source              = "../modules/cognito"
}

module "ecr" {
    depends_on          = [ module.kms ]
    for_each            = local.ecrs
    source              = "../modules/ecr"

    repository          = {
        kms_key_arn     = module.kms.key.arn
        name            = each.value.name
        namespace       = "${local.namespaces.root}/${each.value.namespace}"
        policy          = data.aws_iam_policy_document.lambda_ecr_access[each.key].json
    }
}

module "lambda" {
    depends_on          = [ 
        module.ecr, 
        module.kms,
        module.iam 
    ]
    for_each            = local.endpoints
    source              = "../modules/lambda"

    lambda              = {
        function_name   = each.value.path
        execution_role  = module.iam.service_roles["lambda"]
        image_url       = each.value.image
        kms_key_arn     = module.kms.key.arn
    }
}