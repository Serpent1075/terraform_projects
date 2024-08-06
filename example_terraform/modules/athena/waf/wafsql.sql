--  https://docs.aws.amazon.com/ko_kr/athena/latest/ug/waf-logs.html
--- SELECT Table
SELECT
 count(t.terminatingrule.ruleid) AS count,
 action,
 t.rulegroupid,
 t.terminatingrule.ruleid AS TerminatingRuleID,
 t.nonterminatingmatchingrules
FROM "waf_logs" 
CROSS JOIN UNNEST(rulegrouplist) AS t(t) 
WHERE (date = '2024/02/01' or date = '2024/02/02' or date = '2024/02/03' or date = '2024/02/04' 
or date = '2024/02/05' or date = '2024/02/06' or date = '2024/02/07' or date = '2024/02/08'
 or date = '2024/02/09' or date = '2024/02/10' or date = '2024/02/11' or date = '2024/02/12' 
 or date = '2024/02/13' or date = '2024/02/14' or date = '2024/02/15' or date = '2024/02/16' 
 or date = '2024/02/17' or date = '2024/02/18' or date = '2024/02/19' or date = '2024/02/20' 
 or date = '2024/02/21' or date = '2024/02/22' or date = '2024/02/23' or date = '2024/02/24' 
 or date = '2024/02/25' or date = '2024/02/26' or date = '2024/02/27' or date = '2024/02/28' 
 or date = '2024/02/29' or date = '2024/02/30' or date = '2024/02/31')
AND (t.terminatingrule.ruleid is not null 
OR CARDINALITY(t.nonterminatingmatchingrules) != 0)
GROUP BY action, t.rulegroupid, t.terminatingrule.ruleid, t.nonterminatingmatchingrules
ORDER BY "count" DESC 

SELECT
 count(t.terminatingrule.ruleid) AS count,
 action,
 t.rulegroupid,
 t.terminatingrule.ruleid AS TerminatingRuleID,
 t.nonterminatingmatchingrules
FROM "waf_logs" 
CROSS JOIN UNNEST(rulegrouplist) AS t(t) 
WHERE (date = '2024/02/22' )
AND (t.terminatingrule.ruleid is not null 
AND action <> 'BLOCK'
OR CARDINALITY(t.nonterminatingmatchingrules) != 0)
GROUP BY action, t.rulegroupid, t.terminatingrule.ruleid, t.nonterminatingmatchingrules
ORDER BY "count" DESC 
Limit 500

 
SELECT
 DATE_TRUNC('hour',from_unixtime(timestamp/1000) AT TIME ZONE 'Asia/Seoul') AS time_ISO_8601,
 count(*) AS count,
 httpsourceid,
 httprequest.clientip,
 t.rulegroupid,
 t.terminatingrule.ruleid AS TerminatingRuleID,
 t.nonterminatingmatchingrules,
 httprequest
FROM "waf_logs" 
CROSS JOIN UNNEST(rulegrouplist) AS t(t) 
WHERE (date = '2024/02/22' )
AND (t.terminatingrule.ruleid is not null 
AND (t.terminatingrule.ruleid != 'rate-based' AND t.terminatingrule.ruleid != 'UserAgent_BadBots_HEADER')
OR CARDINALITY(t.nonterminatingmatchingrules) != 0)
GROUP BY DATE_TRUNC('hour',from_unixtime(timestamp/1000) AT TIME ZONE 'Asia/Seoul'), action, httpsourceid, httprequest.clientip, t.rulegroupid, t.terminatingrule.ruleid, t.nonterminatingmatchingrules, httprequest
ORDER BY "count" DESC 
Limit 500

SELECT 
  COUNT(*) AS count,
  webaclid,
  terminatingruleid,
  httprequest.clientip,
  httprequest.uri,
  httprequest
FROM waf_logs
WHERE action='BLOCK'
AND date = '2024/01/11'
GROUP BY webaclid, terminatingruleid, httprequest.clientip, httprequest.uri, httprequest
ORDER BY count DESC
LIMIT 100;


SELECT DATE_TRUNC('hour',from_unixtime(timestamp/1000) AT TIME ZONE 'Asia/Seoul') AS time_ISO_8601, 
httprequest.clientip, COUNT(httprequest.clientip) as count
FROM "default"."waf_logs" 
WHERE date = '2024/01/11'
GROUP BY DATE_TRUNC('hour',from_unixtime(timestamp/1000) AT TIME ZONE 'Asia/Seoul'), httprequest.clientip
ORDER BY count desc



SELECT DATE_TRUNC('hour',from_unixtime(timestamp/1000) AT TIME ZONE 'Asia/Seoul') AS time_ISO_8601, action, httprequest.clientip, terminatingruleid 
FROM "default"."waf_logs" 
WHERE date = '2024/01/11' 
AND httprequest.clientip = '211.249.46.50';

SELECT*FROM waf_logs WHERE date='2024/01/11' limit 10


-- alter table
ALTER TABLE waf_logs ADD PARTITION (`date`='2024/01/11') LOCATION 's3://${var.s3_bucket_name}/AWSLogs/${var.account_id}/2024/01/11'
-- create table
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
PARTITIONED BY ( 
`date` string) 
ROW FORMAT SERDE 
  'org.openx.data.jsonserde.JsonSerDe' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  's3://${var.s3_bucket_name}/AWSLogs/${var.account_id}'
TBLPROPERTIES(
 'projection.enabled' = 'true',
 'projection.date.type' = 'date',
 'projection.date.range' = '2023/01/01,NOW',
 'projection.date.format' = 'yyyy/MM/dd',
 'projection.date.interval' = '1',
 'projection.date.interval.unit' = 'HOURS',
 'storage.location.template' = 's3://${var.s3_bucket_name}/AWSLogs/${var.account_id}/${date}/')