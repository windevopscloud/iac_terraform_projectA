# Drop box for deploy bundles (runner writes, tools EC2 reads)
resource "aws_s3_bucket" "s3_signer_app" {
  bucket        = "s3_signer_app-${data.aws_caller_identity.current.account_id}-${var.environment}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "s3_signer_app" {
  bucket                  = aws_s3_bucket.s3_signer_app.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}