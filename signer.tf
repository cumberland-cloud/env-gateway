resource "aws_signer_signing_profile" "this" {
    name_prefix                 = "${local.namespace_uppercase}Signer"
    platform_id                 = "AWSLambda-SHA384-ECDSA"

    signature_validity_period {
        value                   = 5
        type                    = "YEARS"
    }

}