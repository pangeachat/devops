locals {
  origin_id = var.origin_name
  prefix    = "pangea-${var.env}"
}

resource "aws_cloudfront_distribution" "this" {
  aliases             = var.aliases
  default_root_object = "index.html"
  enabled             = true
  http_version        = "http1.1"
  price_class         = "PriceClass_All"
  is_ipv6_enabled     = true
  # custom_error_response {
  #   error_caching_min_ttl = 300
  #   error_code            = 404
  #   response_code         = 200
  #   response_page_path    = "/index.html"
  # }

  default_cache_behavior {
    allowed_methods = [
      "DELETE",
      "GET",
      "HEAD",
      "OPTIONS",
      "PATCH",
      "POST",
      "PUT",
    ]
    cached_methods = [
      "GET",
      "HEAD",
    ]
    compress               = true
    default_ttl            = 86400
    max_ttl                = 31536000
    min_ttl                = 0
    target_origin_id       = local.origin_id
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      headers                 = []
      query_string            = false
      query_string_cache_keys = []

      cookies {
        forward           = "none"
        whitelisted_names = []
      }
    }
  }

  origin {
    domain_name = aws_s3_bucket.this.bucket_domain_name
    origin_id   = local.origin_id

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols = [
        "SSLv3",
        "TLSv1",
      ]
    }
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1"
    ssl_support_method             = "sni-only"
  }
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}
resource "aws_s3_bucket" "this" {
  bucket = "${local.prefix}-${var.bucket_name}"
  acl    = "public-read"
  website {
    error_document = "index.html"
    index_document = "index.html"
  }
  tags = {
    "STAGE" = var.env
  }
  tags_all = {
    "STAGE" = var.env
  }
}


resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = jsonencode(
    {
      Statement = [
        {
          Action    = "s3:GetObject"
          Effect    = "Allow"
          Principal = "*"
          Resource  = "arn:aws:s3:::${aws_s3_bucket.this.id}/*"
          Sid       = "PublicReadGetObject"
        },
      ]
      Version = "2008-10-17"
    }
  )
}
