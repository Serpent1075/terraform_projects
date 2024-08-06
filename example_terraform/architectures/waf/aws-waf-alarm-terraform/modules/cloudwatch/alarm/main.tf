resource "aws_cloudwatch_metric_alarm" "phpruleset" {
  alarm_name                = "AWSManagedRulesPHPRuleSet_Metric_Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  alarm_description         = "This metric monitors traffic detected by waf rules"
  insufficient_data_actions = []
  treat_missing_data = "notBreaching"
  metric_name = "CountedRequests"
  namespace   = "AWS/WAFV2"
  period              = 120
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    Region = "${var.aws_region}"
    WebACL = "${var.prefix}_WAF_ACL"
    Rule = "AWSManagedRulesPHPRuleSet"
  }
  
  alarm_actions     = [var.sns_arn]
}

resource "aws_cloudwatch_metric_alarm" "linuxruleset" {
  alarm_name                = "AWSManagedRulesLinuxRuleSet"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  alarm_description         = "This metric monitors traffic detected by waf rules"
  insufficient_data_actions = []
  treat_missing_data = "notBreaching"
  metric_name = "CountedRequests"
  namespace   = "AWS/WAFV2"
  period              = 120
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    Region = "${var.aws_region}"
    WebACL = "${var.prefix}_WAF_ACL"
    Rule = "AWSManagedRulesLinuxRuleSet"
  }
  
  alarm_actions     = [var.sns_arn]
}

resource "aws_cloudwatch_metric_alarm" "anonymousiplist" {
  alarm_name                = "AWSManagedRulesAnonymousIpList"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  alarm_description         = "This metric monitors traffic detected by waf rules"
  insufficient_data_actions = []
  treat_missing_data = "notBreaching"
  metric_name = "CountedRequests"
  namespace   = "AWS/WAFV2"
  period              = 120
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    Region = "${var.aws_region}"
    WebACL = "${var.prefix}_WAF_ACL"
    Rule = "AWSManagedRulesAnonymousIpList"
  }
  
  alarm_actions     = [var.sns_arn]
}

resource "aws_cloudwatch_metric_alarm" "knownbadinput" {
  alarm_name                = "AWSManagedRulesKnownBadInputsRuleSet"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  alarm_description         = "This metric monitors traffic detected by waf rules"
  insufficient_data_actions = []
  treat_missing_data = "notBreaching"
  metric_name = "CountedRequests"
  namespace   = "AWS/WAFV2"
  period              = 120
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    Region = "${var.aws_region}"
    WebACL = "${var.prefix}_WAF_ACL"
    Rule = "AWSManagedRulesKnownBadInputsRuleSet"
  }
  
  alarm_actions     = [var.sns_arn]
}

resource "aws_cloudwatch_metric_alarm" "unixruleset" {
  alarm_name                = "AWSManagedRulesUnixRuleSet"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  alarm_description         = "This metric monitors traffic detected by waf rules"
  insufficient_data_actions = []
  treat_missing_data = "notBreaching"
  metric_name = "CountedRequests"
  namespace   = "AWS/WAFV2"
  period              = 120
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    Region = "${var.aws_region}"
    WebACL = "${var.prefix}_WAF_ACL"
    Rule = "AWSManagedRulesUnixRuleSet"
  }
  
  alarm_actions     = [var.sns_arn]
}

resource "aws_cloudwatch_metric_alarm" "commonruleset" {
  alarm_name                = "AWSManagedRulesCommonRuleSet"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  alarm_description         = "This metric monitors traffic detected by waf rules"
  insufficient_data_actions = []
  treat_missing_data = "notBreaching"
  metric_name = "CountedRequests"
  namespace   = "AWS/WAFV2"
  period              = 120
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    Region = "${var.aws_region}"
    WebACL = "${var.prefix}_WAF_ACL"
    Rule = "AWSManagedRulesCommonRuleSet"
  }
  
  alarm_actions     = [var.sns_arn]
}

resource "aws_cloudwatch_metric_alarm" "windowsruleset" {
  alarm_name                = "AWSManagedRulesWindowsRuleSet"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  alarm_description         = "This metric monitors traffic detected by waf rules"
  insufficient_data_actions = []
  treat_missing_data = "notBreaching"
  metric_name = "CountedRequests"
  namespace   = "AWS/WAFV2"
  period              = 120
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    Region = "${var.aws_region}"
    WebACL = "${var.prefix}_WAF_ACL"
    Rule = "AWSManagedRulesWindowsRuleSet"
  }
  
  alarm_actions     = [var.sns_arn]
}

resource "aws_cloudwatch_metric_alarm" "adminprotectionruleset" {
  alarm_name                = "AWSManagedRulesAdminProtectionRuleSet"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  alarm_description         = "This metric monitors traffic detected by waf rules"
  insufficient_data_actions = []
  treat_missing_data = "notBreaching"
  metric_name = "CountedRequests"
  namespace   = "AWS/WAFV2"
  period              = 120
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    Region = "${var.aws_region}"
    WebACL = "${var.prefix}_WAF_ACL"
    Rule = "AWSManagedRulesAdminProtectionRuleSet"
  }
  
  alarm_actions     = [var.sns_arn]
}

resource "aws_cloudwatch_metric_alarm" "sqliruleset" {
  alarm_name                = "AWSManagedRulesSQLiRuleSet"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  alarm_description         = "This metric monitors traffic detected by waf rules"
  insufficient_data_actions = []
  treat_missing_data = "notBreaching"
  metric_name = "CountedRequests"
  namespace   = "AWS/WAFV2"
  period              = 120
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    Region = "${var.aws_region}"
    WebACL = "${var.prefix}_WAF_ACL"
    Rule = "AWSManagedRulesSQLiRuleSet"
  }
  
  alarm_actions     = [var.sns_arn]
}

resource "aws_cloudwatch_metric_alarm" "amazonipreputationlist" {
  alarm_name                = "AWSManagedRulesAmazonIpReputationList"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  alarm_description         = "This metric monitors traffic detected by waf rules"
  insufficient_data_actions = []
  treat_missing_data = "notBreaching"
  metric_name = "CountedRequests"
  namespace   = "AWS/WAFV2"
  period              = 120
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    Region = "${var.aws_region}"
    WebACL = "${var.prefix}_WAF_ACL"
    Rule = "AWSManagedRulesAmazonIpReputationList"
  }
  
  alarm_actions     = [var.sns_arn]
}

resource "aws_cloudwatch_metric_alarm" "wordpressruleset" {
  alarm_name                = "AWSManagedRulesWordPressRuleSet"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  alarm_description         = "This metric monitors traffic detected by waf rules"
  insufficient_data_actions = []
  treat_missing_data = "notBreaching"
  metric_name = "CountedRequests"
  namespace   = "AWS/WAFV2"
  period              = 120
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    Region = "${var.aws_region}"
    WebACL = "${var.prefix}_WAF_ACL"
    Rule = "AWSManagedRulesWordPressRuleSet"
  }
  
  alarm_actions     = [var.sns_arn]
}

resource "aws_cloudwatch_metric_alarm" "customrulegrouplist" {
  alarm_name                = "${var.prefix}_WAF_RULE_GROUP"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  alarm_description         = "This metric monitors traffic detected by waf rules"
  insufficient_data_actions = []
  treat_missing_data = "notBreaching"
  metric_name = "CountedRequests"
  namespace   = "AWS/WAFV2"
  period              = 120
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    Region = "${var.aws_region}"
    WebACL = "${var.prefix}_WAF_ACL"
    Rule = "${var.prefix}_WAF_RULE_GROUP"
  }
  
  alarm_actions     = [var.sns_arn]
}

