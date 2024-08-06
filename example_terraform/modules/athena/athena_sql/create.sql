CREATE EXTERNAL TABLE `waf_logs`(
  `timestamp` bigint,
  `formatversion` int,
  `webaclid` string,
  `terminatingruleid` string,
  `terminatingruletype` string,
  `action` string,
  `terminatingrulematchdetails` array <
                                    struct <
                                        conditiontype: string,
                                        sensitivitylevel: string,
                                        location: string,
                                        matcheddata: array < string >
                                          >
                                     >,
  `httpsourcename` string,
  `httpsourceid` string,
  `rulegrouplist` array <
                      struct <
                          rulegroupid: string,
                          terminatingrule: struct <
                                              ruleid: string,
                                              action: string,
                                              rulematchdetails: array <
                                                                   struct <
                                                                       conditiontype: string,
                                                                       sensitivitylevel: string,
                                                                       location: string,
                                                                       matcheddata: array < string >
                                                                          >
                                                                    >
                                                >,
                          nonterminatingmatchingrules: array <
                                                              struct <
                                                                  ruleid: string,
                                                                  action: string,
                                                                  overriddenaction: string,
                                                                  rulematchdetails: array <
                                                                                       struct <
                                                                                           conditiontype: string,
                                                                                           sensitivitylevel: string,
                                                                                           location: string,
                                                                                           matcheddata: array < string >
                                                                                              >
                                                                                       >
                                                                    >
                                                             >,
                          excludedrules: string
                            >
                       >,
`ratebasedrulelist` array <
                         struct <
                             ratebasedruleid: string,
                             limitkey: string,
                             maxrateallowed: int
                               >
                          >,
  `nonterminatingmatchingrules` array <
                                    struct <
                                        ruleid: string,
                                        action: string,
                                        rulematchdetails: array <
                                                             struct <
                                                                 conditiontype: string,
                                                                 sensitivitylevel: string,
                                                                 location: string,
                                                                 matcheddata: array < string >
                                                                    >
                                                             >,
                                        captcharesponse: struct <
                                                            responsecode: string,
                                                            solvetimestamp: string
                                                             >
                                          >
                                     >,
  `requestheadersinserted` array <
                                struct <
                                    name: string,
                                    value: string
                                      >
                                 >,
  `responsecodesent` string,
  `httprequest` struct <
                    clientip: string,
                    country: string,
                    headers: array <
                                struct <
                                    name: string,
                                    value: string
                                      >
                                 >,
                    uri: string,
                    args: string,
                    httpversion: string,
                    httpmethod: string,
                    requestid: string
                      >,
  `labels` array <
               struct <
                   name: string
                     >
                >,
  `captcharesponse` struct <
                        responsecode: string,
                        solvetimestamp: string,
                        failureReason: string
                          >,
  `challengeresponse` struct <
                          responsecode: string,
                          solvetimestamp: string,
                          failureReason: string
                          >,
  `ja3Fingerprint` string
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
STORED AS INPUTFORMAT 'org.apache.hadoop.mapred.TextInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION 's3://aws-waf-logs-waf-tf/AWSLogs/446860830938/'









CREATE EXTERNAL TABLE `waf_logs_date`(
  `timestamp` bigint,
  `formatversion` int,
  `webaclid` string,
  `terminatingruleid` string,
  `terminatingruletype` string,
  `action` string,
  `terminatingrulematchdetails` array <
                                    struct <
                                        conditiontype: string,
                                        sensitivitylevel: string,
                                        location: string,
                                        matcheddata: array < string >
                                          >
                                     >,
  `httpsourcename` string,
  `httpsourceid` string,
  `rulegrouplist` array <
                      struct <
                          rulegroupid: string,
                          terminatingrule: struct <
                                              ruleid: string,
                                              action: string,
                                              rulematchdetails: array <
                                                                   struct <
                                                                       conditiontype: string,
                                                                       sensitivitylevel: string,
                                                                       location: string,
                                                                       matcheddata: array < string >
                                                                          >
                                                                    >
                                                >,
                          nonterminatingmatchingrules: array <
                                                              struct <
                                                                  ruleid: string,
                                                                  action: string,
                                                                  overriddenaction: string,
                                                                  rulematchdetails: array <
                                                                                       struct <
                                                                                           conditiontype: string,
                                                                                           sensitivitylevel: string,
                                                                                           location: string,
                                                                                           matcheddata: array < string >
                                                                                              >
                                                                                       >
                                                                    >
                                                             >,
                          excludedrules: string
                            >
                       >,
`ratebasedrulelist` array <
                         struct <
                             ratebasedruleid: string,
                             limitkey: string,
                             maxrateallowed: int
                               >
                          >,
  `nonterminatingmatchingrules` array <
                                    struct <
                                        ruleid: string,
                                        action: string,
                                        rulematchdetails: array <
                                                             struct <
                                                                 conditiontype: string,
                                                                 sensitivitylevel: string,
                                                                 location: string,
                                                                 matcheddata: array < string >
                                                                    >
                                                             >,
                                        captcharesponse: struct <
                                                            responsecode: string,
                                                            solvetimestamp: string
                                                             >
                                          >
                                     >,
  `requestheadersinserted` array <
                                struct <
                                    name: string,
                                    value: string
                                      >
                                 >,
  `responsecodesent` string,
  `httprequest` struct <
                    clientip: string,
                    country: string,
                    headers: array <
                                struct <
                                    name: string,
                                    value: string
                                      >
                                 >,
                    uri: string,
                    args: string,
                    httpversion: string,
                    httpmethod: string,
                    requestid: string
                      >,
  `labels` array <
               struct <
                   name: string
                     >
                >,
  `captcharesponse` struct <
                        responsecode: string,
                        solvetimestamp: string,
                        failureReason: string
                          >,
  `challengeresponse` struct <
                        responsecode: string,
                        solvetimestamp: string,
                        failureReason: string
                        >,
  `ja3Fingerprint` string
)
PARTITIONED BY ( 
`region` string, 
`date` string) 
ROW FORMAT SERDE 
  'org.openx.data.jsonserde.JsonSerDe' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  's3://aws-waf-logs-waf-tf/AWSLogs/446860830938/'
TBLPROPERTIES(
 'projection.enabled' = 'true',
 'projection.region.type' = 'enum',
 'projection.region.values' = 'us-east-1,us-west-2,eu-central-1,eu-west-1',
 'projection.date.type' = 'date',
 'projection.date.range' = '2021/01/01,NOW',
 'projection.date.format' = 'yyyy/MM/dd',
 'projection.date.interval' = '1',
 'projection.date.interval.unit' = 'DAYS',
 'storage.location.template' = 's3://DOC-EXAMPLE-BUCKET/AWSLogs/accountID/WAFLogs/${region}/DOC-EXAMPLE-WEBACL/${date}/')