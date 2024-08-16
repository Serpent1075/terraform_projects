resource "aws_wafv2_ip_set" "waf_ip_set" {
   name               = "${var.prefix}_WAF_IPSET"
    description        = "IP set"
    scope              = "REGIONAL"
    ip_address_version = "IPV4"
    addresses          = ["1.2.3.4/32", "5.6.7.8/32"]

    tags = {
    Tag1 = "Value1"
    Tag2 = "Value2"
  }
}

resource "aws_wafv2_regex_pattern_set" "waf_regex_pattern_set" {
  name        = "${var.prefix}_WAF_REGEX_SET"
  description = "WAF regex pattern set"
  scope       = "REGIONAL"

  regular_expression {
    regex_string = "one"
  }

  regular_expression {
    regex_string = "two"
  }

/*
  tags = {
    Tag1 = "Value1"
    Tag2 = "Value2"
  }
  */
}

resource "aws_wafv2_rule_group" "waf_rule_group" {
  name        = "${var.prefix}_WAF_RULE_GROUP"
  description = "An rule group containing all statements"
  scope       = "REGIONAL"
  capacity    = 500

  rule {
    name     = "contain-string"
    priority = 1

    action {
       count {}
    }

    statement {
      not_statement {
        statement {
          and_statement {
            statement {

              geo_match_statement {
                country_codes = var.countrycode
              }
            }

            statement {
              byte_match_statement {
                positional_constraint = "CONTAINS"
                search_string         = "word"

                field_to_match {
                  all_query_arguments {}
                }

                text_transformation {
                  priority = 5
                  type     = "CMD_LINE"
                }

                text_transformation {
                  priority = 2
                  type     = "LOWERCASE"
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "contain-string"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "sqli-match"
    priority = 2

    action {
       count {}
    }

    statement {

      or_statement {
        statement {

          sqli_match_statement {

            field_to_match {
              method {}
            }

            text_transformation {
              priority = 5
              type     = "URL_DECODE"
            }

            text_transformation {
              priority = 4
              type     = "HTML_ENTITY_DECODE"
            }

            text_transformation {
              priority = 3
              type     = "COMPRESS_WHITE_SPACE"
            }
          }
        }

        statement {

          xss_match_statement {

            field_to_match {
              method {}
            }

            text_transformation {
              priority = 2
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "sqli-match"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "query-arguments"
    priority = 3

    action {
       count {}
    }

    statement {

      size_constraint_statement {
        comparison_operator = "GT"
        size                = 100

        field_to_match {
          single_query_argument {
            name = "username"
          }
        }

        text_transformation {
          priority = 5
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "rule-3"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "regex-pattern"
    priority = 4

    action {
       count {}
    }

    statement {

      or_statement {
        statement {

          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.waf_ip_set.arn
          }
        }

        statement {

          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.waf_regex_pattern_set.arn

            field_to_match {
              single_header {
                name = "referer"
              }
            }

            text_transformation {
              priority = 2
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "regex-pattern"
      sampled_requests_enabled   = false
    }
    
  }

    rule {
    name     = "http-method"
    priority = 5

    action {
       count {}
    }

    statement {

      or_statement {
        statement {

          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.waf_ip_set.arn
          }
        }

        statement {

          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.waf_regex_pattern_set.arn

            field_to_match {
              single_header {
                name = "referer"
              }
            }

            text_transformation {
              priority = 2
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "regex-pattern"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "${var.prefix}-CustomRule"
    sampled_requests_enabled   = false
  }

  tags = {
    Name = "Rule Group"
  }
}

resource "aws_wafv2_web_acl" "web_acl" {
  name  = "${var.prefix}_WAF_ACL"
  scope = "REGIONAL"

  default_action {
    block {}
  }

  rule {
    name     = "${var.prefix}-CustomRule"
    priority = 1

    override_action {
       count {}
    }


    statement {
      rule_group_reference_statement {
        arn = aws_wafv2_rule_group.waf_rule_group.arn

      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.prefix}-CustomRule"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "${var.prefix}-ManagedRule"
    priority = 2

    override_action {
       count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        excluded_rule {
          name = "SizeRestrictions_QUERYSTRING"
        }

        excluded_rule {
          name = "NoUserAgent_HEADER"
        }

        scope_down_statement {
          geo_match_statement {
            country_codes = var.countrycode
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.prefix}-ManagedRule"
      sampled_requests_enabled   = true
    }
  }

/*
  tags = {
    Tag1 = "Value1"
    Tag2 = "Value2"
  }
*/
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAF_ACL"
    sampled_requests_enabled   = true
  }
}


resource "aws_wafv2_web_acl_association" "alb_association" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.web_acl.arn
}

/*
resource "aws_wafv2_web_acl_logging_configuration" "logging_config" {
  log_destination_configs = [var.kinesis_arn] // var.kinesis_arn var.log_bucket_arn
  resource_arn            = aws_wafv2_web_acl.web_acl.arn

  logging_filter {
    default_behavior = "KEEP"

    filter {
      behavior = "DROP"

      condition {
        action_condition {
          action = "COUNT"
        }
      }
      requirement = "MEETS_ALL"
    }

    filter {
      behavior = "KEEP"

      condition {
        action_condition {
          action = "ALLOW"
        }
      }

      requirement = "MEETS_ANY"
    }
  }
}


*/