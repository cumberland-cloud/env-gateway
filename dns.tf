resource "aws_route53_record" "example" {
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