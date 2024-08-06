resource "aws_sesv2_configuration_set" "config_set" {
  configuration_set_name = "${var.prefix}_configuration_set"

  delivery_options {
    tls_policy = "REQUIRE"
  }

  reputation_options {
    reputation_metrics_enabled = false
  }

  sending_options {
    sending_enabled = true
  }

  suppression_options {
    suppressed_reasons = ["BOUNCE", "COMPLAINT"]
  }

  tracking_options {
    custom_redirect_domain = "jhoh1075.link"
  }

  
}

resource "aws_sesv2_email_identity" "email_identity" {
  email_identity = var.source_email_address
  configuration_set_name = aws_sesv2_configuration_set.config_set.configuration_set_name
}


resource "aws_sesv2_email_identity_feedback_attributes" "email_identity_attributes" {
  email_identity           = aws_sesv2_email_identity.email_identity.email_identity
  email_forwarding_enabled = true
}