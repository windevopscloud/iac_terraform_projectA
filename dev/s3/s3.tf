# Shared drop box for deploy bundles from all app repos
# (runners write releases/<app>/..., tools EC2 reads)
resource "aws_s3_bucket" "bundles" {
  bucket        = "bundles-${data.aws_caller_identity.current.account_id}-${var.environment}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "bundles" {
  bucket                  = aws_s3_bucket.bundles.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}