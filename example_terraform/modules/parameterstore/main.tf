resource "aws_ssm_parameter" "foo" {
  name  = var.ps_cw_config_name
  type  = "String"
  value = "${data.template_file.ps_cw_config.rendered}"
}

data "template_file" "ps_cw_config" {
  template = "${file("${path.module}/${var.filename}.json.tpl")}"
}
