#화이트리스트 IP세트
resource "aws_wafv2_ip_set" "whitelist_waf_ip_set" {
   name               = "${var.prefix}_Whitelist_WAF_IPSET"
    description        = "IP set"
    scope = "REGIONAL"
    ip_address_version = "IPV4"
    addresses          = [""]

    tags = {
      Name = "${var.prefix}-Whitelist-WAF-IP-Set"
      사용자 = "${var.user_tag}"
    }
    
    lifecycle {
      ignore_changes = [tags]
    }
}

#블랙리스트 IP세트
resource "aws_wafv2_ip_set" "blacklist_waf_ip_set" {
   name               = "${var.prefix}_Blacklist_WAF_IPSET"
    description        = "IP set"
    scope = "REGIONAL"
    ip_address_version = "IPV4"
    addresses          = [""]

    tags = {
      Name = "${var.prefix}-Blacklist-WAF-IP-Set"
      사용자 = "${var.user_tag}"
    }
    
    lifecycle {
      ignore_changes = [tags]
    }
}

#정규표현식 패턴
resource "aws_wafv2_regex_pattern_set" "waf_regex_pattern_set_uri_path" {
  name        = "${var.prefix}_WAF_REGEX_URI_PATH_SET"
  description = "WAF regex uri path pattern set"
  scope = "REGIONAL"

/*
  //SQL 인젝션 공격 탐지
  regular_expression {
    regex_string = "(?i)\\bselect\\b|\\binsert\\b|\\bupdate\\b|\\bdelete\\b|\\bwhere\\b|\\bunion\\b|\\bjoin\\b|\\blike\\b|\\border\\b|\\bby\\b|\\blimit\\b"
  }

  //DDoS 인젝션 공격 탐지
  regular_expression {
    regex_string = "(?i)\\battack\\b|\\bflood\\b|\\bdos\\b|\\bbomb\\b|\\bnuke\\b|\\bcrash\\b|\\bkill\\b|\\bdie\\b"
  }

  //log4j 공격
  regular_expression {
    regex_string =  "\\/TomcatBypass\\/Command\\/Base64\\/[a-zA-Z0-9+\\/=]+"
  }
  */

 tags = {
    Name = "${var.prefix}-WAF-Regex-Pattern-Set"
    사용자 = "${var.user_tag}"
  }
  
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_wafv2_regex_pattern_set" "waf_regex_pattern_set_header" {
  name        = "${var.prefix}_WAF_REGEX_HEADER_SET"
  description = "WAF regex header pattern set"
  scope = "REGIONAL"
/*
  //SQL 인젝션 공격 탐지
  regular_expression {
    regex_string = "(?i)\\bselect\\b|\\binsert\\b|\\bupdate\\b|\\bdelete\\b|\\bwhere\\b|\\bunion\\b|\\bjoin\\b|\\blike\\b|\\border\\b|\\bby\\b|\\blimit\\b"
  }

  //DDoS 인젝션 공격 탐지
  regular_expression {
    regex_string = "(?i)\\battack\\b|\\bflood\\b|\\bdos\\b|\\bbomb\\b|\\bnuke\\b|\\bcrash\\b|\\bkill\\b|\\bdie\\b"
  }

  //워너크라이 확장자
  regular_expression {
    regex_string = "\\.(exe|dll|jpg|png|zip|rar|doc|docx|xls|xlsx|ppt|pptx|pdf|txt)"
  }

  //워너크라이 헤더
  regular_expression {
    regex_string = "\\xfd\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00"
  }

  //Slowloris 공격
  regular_expression {
    regex_string =  "(GET|POST|HEAD|OPTIONS|PUT|DELETE|TRACE|CONNECT)\\s*(.*)\\s*Host: (.*)\\s*Connection: keep-alive"
  }

  //Slowread 공격
  regular_expression {
    regex_string =  "(GET|POST|HEAD|OPTIONS|PUT|DELETE|TRACE|CONNECT)\\s*(.*)\\s*Host: (.*)\\s*Content-Length: ([0-9]+)"
  }
*/
 tags = {
    Name = "${var.prefix}-WAF-Regex-Pattern-Set"
    사용자 = "${var.user_tag}"
  }
  
  lifecycle {
    ignore_changes = [tags]
  }
}


resource "aws_wafv2_regex_pattern_set" "waf_regex_pattern_set_body" {
  name        = "${var.prefix}_WAF_REGEX_BODY_SET"
  description = "WAF regex body pattern set"
  scope = "REGIONAL"

/*
  //SQL 인젝션 공격 탐지
  regular_expression {
    regex_string = "(?i)\\bselect\\b|\\binsert\\b|\\bupdate\\b|\\bdelete\\b|\\bwhere\\b|\\bunion\\b|\\bjoin\\b|\\blike\\b|\\border\\b|\\bby\\b|\\blimit\\b"
  }

  //DDoS 인젝션 공격 탐지
  regular_expression {
    regex_string = "(?i)\\battack\\b|\\bflood\\b|\\bdos\\b|\\bbomb\\b|\\bnuke\\b|\\bcrash\\b|\\bkill\\b|\\bdie\\b"
  }

  //XSS 공격 탐지
  regular_expression {
    regex_string = "(?i)</script>|<script>|\\bonload\\b|\\bsrc\\b|\\beval\\b|\\bexpression\\b"
  }

  //악성 스크립트 공격 탐지
  regular_expression {
    regex_string = "(?i)\\bjavascript\\b|\\bvbscript\\b|\\bphp\\b|\\basp\\b|\\bperl\\b"
  }

  //워너크라이 Body
  regular_expression {
    regex_string = "[a-z0-9]{32}[a-z0-9]{16}[a-z0-9]{8}[a-z0-9]{24}[a-z0-9]{16}[a-z0-9]{32}"
  }

*/


 tags = {
    Name = "${var.prefix}-WAF-Regex-Pattern-Set"
    사용자 = "${var.user_tag}"
  }
  
  lifecycle {
    ignore_changes = [tags]
  }
}


resource "aws_wafv2_rule_group" "waf_rule_group" {
  name        = "${var.prefix}_WAF_RULE_GROUP"
  description = "An rule group containing all statements"
  scope = "REGIONAL"
  capacity    = 300


  rule {
    name     = "blacklist-ip-set"
    priority = 100

    action {
      block{}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.blacklist_waf_ip_set.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "blacklist-ip-set"
      sampled_requests_enabled   = true
    }
    
  }

  rule {
    name     = "whitelist-ip-set"
    priority = 200

    action {
      allow{}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.whitelist_waf_ip_set.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "whitelist-ip-set"
      sampled_requests_enabled   = true
    }
    
  }

  rule {
    name     = "country-block"
    priority = 300

    action {
      block {}
    }

    statement {
      geo_match_statement {
        country_codes = var.countrycode
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "contain-string"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "rate-based"
    priority = 400

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit = 360
      }
    }
    

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-based"
      sampled_requests_enabled   = true
    }
  }

    rule {
    name     = "regex-pattern-uri-path"
    priority = 500

    action {
      block {}
    }

    statement {
      regex_pattern_set_reference_statement {
        arn = aws_wafv2_regex_pattern_set.waf_regex_pattern_set_uri_path.arn

        field_to_match {
          uri_path{
          }
        }

        text_transformation {
          priority = 1
          type     = "NONE"  //텍스트 변환 없음
        }

/*
        text_transformation {
          priority = 2
          type     = "URL_DECODE"  //url 디코딩
        }

        text_transformation {
          priority = 3
          type     = "BASE64_DECODE_EXT"  //base64 디코딩을 하지만 유효하지 않은 문자열은 무시
        }
*/
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "regex-pattern-header"
      sampled_requests_enabled   = true
    }
    
  }
  
  rule {
    name     = "regex-pattern-header"
    priority = 600

    action {
      block {}
    }

    statement {
      regex_pattern_set_reference_statement {
        arn = aws_wafv2_regex_pattern_set.waf_regex_pattern_set_header.arn

        field_to_match {
          headers{
            match_pattern {
              all{}
            }
            match_scope = "ALL"
            oversize_handling =  "CONTINUE" 
            // CONTINUE: 룰의 조사기준에 따른 사이즈 한도에 따라 컨텐츠를 조사
            // Match: 해당 패턴에 매칭이되는
            // NO_MATCH: 해당 패턴에 매칭이되지 않는
          }
        }

        text_transformation {
          priority = 1
          type     = "NONE"  //텍스트 변환 없음
        }

/*
        text_transformation {
          priority = 2
          type     = "URL_DECODE"  //url 디코딩
        }

        text_transformation {
          priority = 3
          type     = "BASE64_DECODE_EXT"  //base64 디코딩을 하지만 유효하지 않은 문자열은 무시
        }
*/
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "regex-pattern-header"
      sampled_requests_enabled   = true
    }
    
  }

  rule {
    name     = "regex-pattern-body"
    priority = 700

    action {
      block {}
    }

    statement {
      regex_pattern_set_reference_statement {
        arn = aws_wafv2_regex_pattern_set.waf_regex_pattern_set_body.arn

        field_to_match {
          json_body{
            invalid_fallback_behavior = "EVALUATE_AS_STRING"
            match_pattern {
               all{}
            }
            match_scope = "ALL"
            oversize_handling = "CONTINUE"
          }
        }
        
        text_transformation {
          priority = 1
          type     = "NONE"  //텍스트 변환 없음
        }

/*
        text_transformation {
          priority = 2
          type     = "URL_DECODE"  //url 디코딩
        }

        text_transformation {
          priority = 3
          type     = "BASE64_DECODE_EXT"  //base64 디코딩을 하지만 유효하지 않은 문자열은 무시
        }
*/
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "regex-pattern-body"
      sampled_requests_enabled   = true
    }
    
  }


  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.prefix}_WAF_RULE_GROUP"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.prefix}_WAF_RULE_GROUP"
    사용자 = "${var.user_tag}"
  }
  
  lifecycle {
    ignore_changes = [tags]
  }
}


resource "aws_wafv2_web_acl" "web_acl" {
  
  name  = "${var.prefix}_WAF_ACL"
  scope = "REGIONAL"

  default_action {
    allow {}
  }


  rule {
    name     = "${var.prefix}_WAF_RULE_GROUP"
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
      metric_name                = "${var.prefix}_WAF_RULE_GROUP"
      sampled_requests_enabled   = true
    }
  }

 
  rule {
    name     = "AWSManagedRulesWordPressRuleSet"
    priority = 10
   

    override_action {
       count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesWordPressRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesWordPressRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesWindowsRuleSet"
    priority = 11
   

    override_action {
       count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesWindowsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesWindowsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesUnixRuleSet"
    priority = 12
   

    override_action {
       count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesUnixRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesUnixRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesPHPRuleSet"
    priority = 13
   

    override_action {
       count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesPHPRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesPHPRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesLinuxRuleSet"
    priority = 14
   

    override_action {
       count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesLinuxRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 15
   

    override_action {
       count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 16
   
    override_action {
       count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAnonymousIpList"
    priority = 17
   
    override_action {
       count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAnonymousIpList"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 18
   
    override_action {
       count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAdminProtectionRuleSet"
    priority = 19
   
    override_action {
       count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAdminProtectionRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAdminProtectionRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 20
   
    override_action {
       count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }


  tags = {
    Name = "${var.prefix}-WAF"
    사용자 = "${var.user_tag}"
  }
  
  lifecycle {
    ignore_changes = [tags]
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAF_ACL"
    sampled_requests_enabled   = true
  }
}

// 아래의 리소스는 Cloudfront와 동시에 사용할 수 없습니다.
// 기존 ALB가 있을 경우 arn을 주입시 WAF에 자동으로 연결됩니다.
// 초기 구축 시 ALB를 WAF에 바로 연결하는 것은 권장하지 않습니다.
/*
resource "aws_wafv2_web_acl_association" "alb_association" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.web_acl.arn
}
*/

resource "aws_wafv2_web_acl_logging_configuration" "logging_config" {
  log_destination_configs = [var.kinesis_arn] // var.kinesis_arn var.log_bucket_arn
  resource_arn            = aws_wafv2_web_acl.web_acl.arn

  logging_filter {
    default_behavior = "KEEP"

    filter {
      behavior = "KEEP"

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
          action = "BLOCK"
        }
      }

      requirement = "MEETS_ANY"
    }
  }
}
