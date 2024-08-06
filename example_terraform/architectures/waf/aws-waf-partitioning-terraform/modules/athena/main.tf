resource "aws_athena_database" "waflogs" {
  name   = "aws_waf_logs_db"
  bucket = var.s3_bucket_id
}

resource "aws_athena_workgroup" "waflogs" {
  name = "aws-waf-workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
   

    result_configuration {
      output_location = "s3://${var.s3_bucket_name}/output/athenaquery"
     acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
     }

     encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}

resource "aws_athena_named_query" "createtable" {
  name      = "createwaftable"
  workgroup = aws_athena_workgroup.waflogs.id
  database  = aws_athena_database.waflogs.name
  query     = "CREATE EXTERNAL TABLE `waf_logs`(`timestamp` bigint,`formatversion` int,`webaclid` string,`terminatingruleid` string,`terminatingruletype` string,`action` string,`terminatingrulematchdetails` array <struct <conditiontype: string,sensitivitylevel: string,location: string,matcheddata: array < string >>>,`httpsourcename` string,`httpsourceid` string,`rulegrouplist` array <struct <rulegroupid: string,terminatingrule: struct <ruleid: string, action: string, rulematchdetails: array < struct < conditiontype: string, sensitivitylevel: string, location: string, matcheddata: array < string > > > >, nonterminatingmatchingrules: array < struct < ruleid: string, action: string, overriddenaction: string, rulematchdetails: array < struct < conditiontype: string, sensitivitylevel: string, location: string, matcheddata: array < string > > > >>, excludedrules: string > >, `ratebasedrulelist` array < struct < ratebasedruleid: string, limitkey: string, maxrateallowed: int > >, `nonterminatingmatchingrules` array < struct < ruleid: string, action: string, rulematchdetails: array <struct < conditiontype: string, sensitivitylevel: string, location: string, matcheddata: array < string > >>, captcharesponse: struct < responsecode: string, solvetimestamp: string> > >, `requestheadersinserted` array < struct < name: string, value: string >>, `responsecodesent` string, `httprequest` struct < clientip: string, country: string, headers: array < struct < name: string, value: string >>, uri: string, args: string, httpversion: string, httpmethod: string, requestid: string >, `labels` array < struct < name: string > >, `captcharesponse` struct < responsecode: string, solvetimestamp: string, failureReason: string >, `challengeresponse` struct < responsecode: string, solvetimestamp: string, failureReason: string >, `ja3Fingerprint` string ) PARTITIONED BY (  `date` string)  ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'  STORED AS INPUTFORMAT 'org.apache.hadoop.mapred.TextInputFormat'  OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat' LOCATION 's3://${var.s3_bucket_name}/AWSLogs/${var.account_id}' TBLPROPERTIES('projection.enabled' = 'true','projection.date.type' = 'date','projection.date.range' = '2023/01/01,NOW','projection.date.format' = 'yyyy/MM/dd','projection.date.interval' = '1','projection.date.interval.unit' = 'HOURS','storage.location.template' = 's3://${var.s3_bucket_name}/AWSLogs/${var.account_id}/$${date}/');" 
}

resource "aws_athena_named_query" "altertable" {
  name      = "altertable"
  workgroup = aws_athena_workgroup.waflogs.id
  database  = aws_athena_database.waflogs.name
  query     = "ALTER TABLE waf_logs ADD PARTITION (`date`='2024/02/09') LOCATION 's3://${var.s3_bucket_name}/AWSLogs/${var.account_id}/2024/02/09'" 
}

