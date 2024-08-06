provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}
#cloudfont에서 사용되는 ACM은 us-east-1에 생성된 인증서를 가져와야합니다.
#data는 provider에서 설정된 리전을 기준으로 생성된 리소스를 찾으므로
#임시적으로 provider를 us-east-1로 설정 후 data에 적용시켜야합니다.
data "aws_acm_certificate" "amazon_issued" {
  domain      = var.domain_address
  types       = ["AMAZON_ISSUED"]
  most_recent = true
  provider = aws.virginia
}

resource "aws_cloudfront_cache_policy" "cloudfornt_cache_policy" {
  name        = "${var.prefix}-cache-policy"
  comment     = "${var.prefix} cache policy"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 1
  
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip = true

    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "whitelist"
      query_strings {
        items = ["w","h","webp","q"]
      }
    }
  }
}

data "aws_cloudfront_origin_request_policy" "cloudfornt_origin_request_policy" {
  name = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_response_headers_policy" "cloudfornt_response_headers_policy" {
  name = "Managed-SimpleCORS"
}

resource "aws_cloudfront_origin_access_identity" "cloudfront_oai" {
  comment = "OAI for AWS CloudFront"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
   origin_group {
    origin_id = "groupS3"

    failover_criteria {
      status_codes = [403, 404, 500, 502]
    }

    member {
      origin_id = var.propic_origin_path
    }

    member {
      origin_id = var.terms_origin_path
    }
  }

  origin {
    domain_name = var.bucket_regional_domain_name
    origin_id   = var.propic_origin_path
    origin_path = "/${var.propic_origin_path}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cloudfront_oai.cloudfront_access_identity_path
    }
  }
  origin {
    domain_name = var.bucket_regional_domain_name
    origin_id   = var.terms_origin_path
    origin_path = "/${var.terms_origin_path}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cloudfront_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN Distribution for service"
  default_root_object = "index.html"



  logging_config {
    include_cookies = false
    bucket          = var.log_bucket_name
    prefix          = var.log_bucket_prefix
  }

  aliases = var.list_alias_domain

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "groupS3"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "pic/*" #/wildcard 필수
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = var.propic_origin_path
    cache_policy_id = aws_cloudfront_cache_policy.cloudfornt_cache_policy.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cloudfornt_origin_request_policy.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.cloudfornt_response_headers_policy.id

 
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    
    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = var.viewer_req_lambda_arn
      include_body = true
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = var.origin_resp_lambda_arn
      include_body = false
    }
    
  }

  ordered_cache_behavior {
    path_pattern     = "policy/*" #/wildcard 필수
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = var.terms_origin_path
    cache_policy_id = aws_cloudfront_cache_policy.cloudfornt_cache_policy.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cloudfornt_origin_request_policy.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.cloudfornt_response_headers_policy.id

   
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    /*
    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = var.viewer_req_lambda_arn
      include_body = true
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = var.origin_resp_lambda_arn
      include_body = false
    }
    */
  }

  price_class = "PriceClass_200"

  
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE", "KR"]
    }
  }
  
  tags = {
    Environment = "production"
  }

  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.amazon_issued.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method = "sni-only" #vip 선택 시 월 600달러 -> 각 엣지로케이션 마다 전용 IP 할당
  }
}

data "aws_iam_policy_document" "cloudfront_s3_policy" {
  statement {
    sid = "cf-s3"
    actions   = ["s3:GetObject"]
    resources = ["${var.origin_bucket_arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [
        aws_cloudfront_origin_access_identity.cloudfront_oai.iam_arn,
        var.lambda_iam_arn
      ]
    }
  }
  statement {
    sid = "ec2-s3"
    actions   = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["${var.origin_bucket_arn}/*","${var.origin_bucket_arn}"]

    principals {
      type        = "AWS"
      identifiers = [var.ec2_iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_s3_access" {
  bucket = var.origin_bucket_id
  policy = data.aws_iam_policy_document.cloudfront_s3_policy.json
}
