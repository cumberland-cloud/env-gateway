resource "aws_signer_signing_profile" "this" {
    name_prefix                 = "${local.root_namespace}-signer"
    platform_id                 = "AWSLambda-SHA384-ECDSA"

    signature_validity_period {
        value                   = 5
        type                    = "YEARS"
    }

}