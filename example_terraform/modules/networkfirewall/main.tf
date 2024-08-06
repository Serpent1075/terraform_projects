resource "aws_networkfirewall_firewall" "network_firewall" {
  name                = "${var.prefix}-network-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.firewall_policy.arn
  vpc_id              = var.vpc_id
  subnet_mapping {
    subnet_id = var.subnet_ids[0]
  }
  subnet_mapping {
    subnet_id = var.subnet_ids[1]
  }

  tags = {
    Name = "${var.prefix}_network_firewall"
  }
}

resource "aws_networkfirewall_firewall_policy" "firewall_policy" {
  name = "${var.prefix}-firewall-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:pass"]
    stateless_fragment_default_actions = ["aws:drop"]
    stateful_engine_options {
        rule_order = "DEFAULT_ACTION_ORDER" //DEFAULT_ACTION_ORDER STRICT_ORDER
    }
    stateful_rule_group_reference {
      //priority     = 1
      resource_arn = aws_networkfirewall_rule_group.network_firewall_rule_group.arn
    }
  }

  tags = {
    Name = "${var.prefix}_firewall_policy"
  }
}

resource "aws_networkfirewall_resource_policy" "network_firewall_resource_policy" {
  resource_arn = aws_networkfirewall_rule_group.network_firewall_rule_group.arn
  # policy's Action element must include all of the following operations
  policy = jsonencode({
    Statement = [{
      Action = [
        "network-firewall:ListRuleGroups",
        "network-firewall:CreateFirewallPolicy",
        "network-firewall:UpdateFirewallPolicy"
      ]
      Effect   = "Allow"
      Resource = "${aws_networkfirewall_rule_group.network_firewall_rule_group.arn}"
      Principal = {
        AWS = "arn:aws:iam::${var.account_id}:root"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_networkfirewall_rule_group" "network_firewall_rule_group" {
  capacity = 2000
  name     = "${var.prefix}-rule-group"
  type     = "STATEFUL"
  rules    = file("./modules/networkfirewall/malware.rules")

  tags = {
    Name = "${var.prefix}-rule-group"
  }
}