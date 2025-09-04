# Create private hosted zone for S3
resource "aws_route53_zone" "s3" {
  name = "s3.amazonaws.com"

  vpc {
    vpc_id = data.aws_vpc.selected.id
  }

  comment = "Private zone for S3 endpoint"
}

# Create alias record for the specific EKS bucket
resource "aws_route53_record" "eks_s3" {
  zone_id = aws_route53_zone.s3.id
  name    = "amazon-eks.s3.amazonaws.com"
  type    = "A"

  alias {
    name                   = aws_vpc_endpoint.s3.dns_entry[0].dns_name
    zone_id                = aws_vpc_endpoint.s3.dns_entry[0].hosted_zone_id
    evaluate_target_health = true
  }
}