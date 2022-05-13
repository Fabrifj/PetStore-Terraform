resource "aws_s3_bucket" "pet_store_s3_bucket" {
  bucket = "s3-website-test.petstore.com"
  acl    = "public-read"
  
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT","POST"]
    allowed_origins = ["*"]
    expose_headers = ["ETag"]
    max_age_seconds = 3000
  }

}
resource "aws_s3_bucket_website_configuration" "pet_store_s3_wc" {
  bucket = aws_s3_bucket.pet_store_s3_bucket.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  routing_rule {
    condition {
      key_prefix_equals = "docs/"
    }
    redirect {
      replace_key_prefix_with = "documents/"
    }
  }
}
resource "aws_s3_bucket_policy" "pet_store_s3_bucket_policy" {
  bucket = aws_s3_bucket.pet_store_s3_bucket.bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          aws_s3_bucket.pet_store_s3_bucket.arn,
          "${aws_s3_bucket.pet_store_s3_bucket.arn}/*",
        ]
      },
    ]
  })
}



