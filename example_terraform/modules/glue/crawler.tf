resource "aws_glue_classifier" "csv_classifier" {
  name = "${var.prefix}-csv-classifier"

  csv_classifier {
    allow_single_column    = false
    contains_header        = "UNKNOWN" //detect headings = unknown
    delimiter              = ","
    disable_value_trimming = false
    quote_symbol           = "\""
  }
}


resource "aws_glue_crawler" "catalog_crawler" {
  database_name = aws_glue_catalog_database.single_glue_database.name
  name          = "${var.prefix}-crawler"
  role          = var.glue_iam_role_arn
  classifiers = [aws_glue_classifier.csv_classifier.name]

  s3_target {
    path = "s3://cmtcloud.biz/CUR-Report/CMT-CUR/"
  }

  configuration = jsonencode(
    {
      Grouping = {
        TableGroupingPolicy = "CombineCompatibleSchemas"
      }
      
      Version = 1
    }
  )
}
