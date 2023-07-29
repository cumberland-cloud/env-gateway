resource "aws_route53_record" "this" {
  name                      = aws_api_gateway_domain_name.this.domain_name
  type                      = "A"
  zone_id                   = data.aws_route53_zone.domain.id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.this.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.this.cloudfront_zone_id
  }
}

resource "aws_api_gateway_domain_name" "this" {
  certificate_arn               = data.aws_acm_certificate_validation.domain.certificate_arn
  domain_name                   = "api.${local.domain}"
}

resource "aws_api_gateway_base_path_mapping" "this" {
  api_id                        = aws_api_gateway_rest_api.this.id
  stage_name                    = aws_api_gateway_stage.this.stage_name
  domain_name                   = aws_api_gateway_domain_name.this.domain_name
}