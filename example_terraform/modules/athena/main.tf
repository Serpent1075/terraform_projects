resource "aws_athena_data_catalog" "example" {
  name        = "${var.prefix}-catalog"
  description = "Glue based Data Catalog"
  type        = "GLUE"

  parameters = {
    "catalog-id" = "123456789012"
  }
}