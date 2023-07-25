data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_acm_certificate" "issued" {
  domain                        = "*.${local.domain}"
  statuses                      = [ "ISSUED" ]
}


data "aws_iam_policy_document" "ecr_access" {
    for_each                    = local.ecr_endpoint_access

    statement {
        sid                     = "EnableLambdaAccess"
        effect                  = "Allow"
        actions                 = [ 
            "ecr:BatchGetImage",
            "ecr:GetDownloadUrlForLayer"
        ]

        principals {
            type                =  "Service"
            identifiers         = [
                "lambda.amazonaws.com"
            ]
        }

        condition {
            test                = "ArnLike"
            variable            = "aws:SourceArn"
            values              = [  
                for function_name in each.value: "${local.lambda_prefix}:${function_name}:*"
            ]
        }
  }
}