package main

import (
	"context"
	"encoding/csv"
	"log"
	"os"
	"strconv"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/athena"
	"github.com/aws/aws-sdk-go-v2/service/athena/types"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/sts"
)

func analyzer(ctx context.Context, event events.CloudWatchEvent) {
	cfg, cfgerr := config.LoadDefaultConfig(
		context.Background(),
	)
	check("cfgerr", cfgerr)
	result := ExecuteAthenaQuery(cfg)
	accountid := GetAccountId(cfg)
	filename := MakeCSV(cfg, accountid, result)
	PutCSVToS3(cfg, filename, accountid)

}

func ExecuteAthenaQuery(cfg aws.Config) Result {
	date := GetDate()

	ruleallowquery := GetRuleAllowQuery(date)
	log.Println(ruleallowquery)
	ruleallowqueryid := ExecQuery(cfg, ruleallowquery)

	ruleblockquery := GetRuleBlockQuery(date)
	log.Println(ruleblockquery)
	ruleblockqueryid := ExecQuery(cfg, ruleblockquery)

	ruleallinboundquery := GetAllInboundQuery(date)
	log.Println(ruleallinboundquery)
	ruleallinboundqueryid := ExecQuery(cfg, ruleallinboundquery)

	urlallowedcountquery := GetAllowedUrlCountQuery(date)
	log.Println(urlallowedcountquery)
	urlallowedcountqueryid := ExecQuery(cfg, urlallowedcountquery)

	urlblockedcountquery := GetBlockedUrlCountQuery(date)
	log.Println(urlblockedcountquery)
	urlblockedcountqueryid := ExecQuery(cfg, urlblockedcountquery)

	pathallowedcountquery := GetAllowedPathCountQuery(date)
	log.Println(pathallowedcountquery)
	pathallowedcountqueryid := ExecQuery(cfg, pathallowedcountquery)

	pathblockedcountquery := GetBlockedPathCountQuery(date)
	log.Println(pathallowedcountquery)
	pathblockedcountqueryid := ExecQuery(cfg, pathblockedcountquery)

	urlandpathallowedcountquery := GetAllowedUrlAndPathDetailQuery(date)
	log.Println(urlandpathallowedcountquery)
	urlandpathallowedcountqueryid := ExecQuery(cfg, urlandpathallowedcountquery)

	urlandpathblockedcountquery := GetBlockedUrlAndPathDetailQuery(date)
	log.Println(urlandpathblockedcountquery)
	urlandpathblockedcountqueryid := ExecQuery(cfg, urlandpathblockedcountquery)

	countryquery := GetCountryInboundQuery(date)
	log.Println(countryquery)
	countryqueryid := ExecQuery(cfg, countryquery)

	result := Result{
		RuleAllowQueryID:                  ruleallowqueryid,
		RuleBlockQueryID:                  ruleblockqueryid,
		RuleAllInboundQueryID:             ruleallinboundqueryid,
		GetAllowedUrlCountQueryID:         urlallowedcountqueryid,
		GetBlockedUrlCountQueryID:         urlblockedcountqueryid,
		GetAllowedPathCountQueryID:        pathallowedcountqueryid,
		GetBlockedPathCountQueryID:        pathblockedcountqueryid,
		GetAllowedUrlAndPathDetailQueryID: urlandpathallowedcountqueryid,
		GetBlockedUrlAndPathDetailQueryID: urlandpathblockedcountqueryid,
		CountryQueryID:                    countryqueryid,
	}
	return result
}

type Result struct {
	RuleAllowQueryID                  *string
	RuleBlockQueryID                  *string
	RuleAllInboundQueryID             *string
	GetAllowedUrlCountQueryID         *string
	GetBlockedUrlCountQueryID         *string
	GetAllowedPathCountQueryID        *string
	GetBlockedPathCountQueryID        *string
	GetAllowedUrlAndPathDetailQueryID *string
	GetBlockedUrlAndPathDetailQueryID *string
	CountryQueryID                    *string
}

func PutCSVToS3(cfg aws.Config, filename string, accountid string) {
	file, err := os.Open("/tmp/queryresult/" + filename)
	check("fileopen err: ", err)
	defer file.Close()
	s3client := s3.NewFromConfig(cfg)
	s3input := s3.PutObjectInput{
		Bucket:              aws.String(os.Getenv("BUCKET_NAME")),
		Key:                 aws.String("output/waflog_query_state/" + filename),
		ExpectedBucketOwner: aws.String(accountid),
		Body:                file,
	}
	_, outputerr := s3client.PutObject(context.Background(), &s3input)
	check("puts3upload", outputerr)

}

func MakeCSV(cfg aws.Config, accountid string, result Result) string {

	mkdirerr := os.MkdirAll("/tmp/queryresult/", 0770)
	check("mkdirerr", mkdirerr)
	filename := "waflog_query_id_" + strconv.Itoa(time.Now().Year()) + "_" + getDateString(int(time.Now().Month()-1)) + ".csv"
	file, err := os.Create("/tmp/queryresult/" + filename)
	if err != nil {
		check("filecreate err", err)
	}
	defer file.Close()

	// CSV Writer 생성
	writer := csv.NewWriter(file)
	defer writer.Flush()

	// 헤더 쓰기
	err = writer.Write([]string{"RuleAllowQueryID", "RuleBlockQueryID", "RuleAllInboundQueryID", "GetAllowedUrlCountQueryID", "GetBlockedUrlCountQueryID", "GetAllowedPathCountQueryID", "GetBlockedPathCountQueryID", "GetAllowedUrlAndPathDetailQueryID", "GetBlockedUrlAndPathDetailQueryID", "CountryQueryID"})
	if err != nil {
		check("file writeheader err", err)
	}

	err = writer.Write([]string{*result.RuleAllowQueryID, *result.RuleBlockQueryID, *result.RuleAllInboundQueryID, *result.GetAllowedUrlCountQueryID, *result.GetBlockedUrlCountQueryID, *result.GetAllowedPathCountQueryID, *result.GetBlockedPathCountQueryID, *result.GetAllowedUrlAndPathDetailQueryID, *result.GetBlockedUrlAndPathDetailQueryID, *result.CountryQueryID})
	if err != nil {
		check("file write value err", err)
	}
	return filename
}

func ExecQuery(cfg aws.Config, query string) *string {
	athenaclient := athena.NewFromConfig(cfg)
	typequery := types.QueryExecutionContext{
		Catalog:  aws.String("AwsDataCatalog"),
		Database: aws.String(os.Getenv("DATABASE_NAME")),
	}

	athenaqueryinput := athena.StartQueryExecutionInput{
		QueryString:           aws.String(query),
		QueryExecutionContext: &typequery,
		WorkGroup:             aws.String(os.Getenv("WORKGROUP_NAME")),
	}

	athenaqueryoutput, athenaqueryerr := athenaclient.StartQueryExecution(context.Background(), &athenaqueryinput)
	check("athenaqueryerr", athenaqueryerr)
	log.Println(*athenaqueryoutput.QueryExecutionId)
	return athenaqueryoutput.QueryExecutionId
}

func GetBlockedUrlAndPathDetailQuery(date string) string {
	query := "WITH dataset AS ( SELECT count(t.terminatingrule.ruleid) AS count, httprequest.uri AS path, header, action, t.rulegroupid AS rulegroupid, t.terminatingrule.ruleid AS TerminatingRuleID, t.nonterminatingmatchingrules AS NonTerminatingRules FROM \"waf_logs\" CROSS JOIN UNNEST(rulegrouplist) AS t(t) CROSS JOIN UNNEST (httprequest.headers) AS s(header) WHERE ("
	query += date
	query += ") AND (action = 'BLOCK') AND (t.terminatingrule.ruleid is not null OR CARDINALITY (t.nonterminatingmatchingrules) != 0) GROUP BY action,t.rulegroupid, httprequest.uri, s.header,t.terminatingrule.ruleid, t.nonterminatingmatchingrules) SELECT count, header.value, path, action, rulegroupid, TerminatingRuleID, NonTerminatingRules FROM dataset WHERE header.name='Host' GROUP BY count, header.value, path, action, rulegroupid, TerminatingRuleID, NonTerminatingRules ORDER BY count DESC"
	return query
}

func GetAllowedUrlAndPathDetailQuery(date string) string {
	query := "WITH dataset AS ( SELECT count(t.terminatingrule.ruleid) AS count, httprequest.uri AS path, header, action, t.rulegroupid AS rulegroupid, t.terminatingrule.ruleid AS TerminatingRuleID, t.nonterminatingmatchingrules AS NonTerminatingRules FROM \"waf_logs\" CROSS JOIN UNNEST(rulegrouplist) AS t(t) CROSS JOIN UNNEST (httprequest.headers) AS s(header) WHERE ("
	query += date
	query += ") AND (action = 'ALLOW') AND (t.terminatingrule.ruleid is not null OR CARDINALITY (t.nonterminatingmatchingrules) != 0) GROUP BY action,t.rulegroupid, httprequest.uri, s.header,t.terminatingrule.ruleid, t.nonterminatingmatchingrules) SELECT count, header.value, path, action, rulegroupid, TerminatingRuleID, NonTerminatingRules FROM dataset WHERE header.name='Host' GROUP BY count, header.value, path, action, rulegroupid, TerminatingRuleID, NonTerminatingRules ORDER BY count DESC"
	return query
}

func GetBlockedPathCountQuery(date string) string {
	query := "SELECT count(httprequest.uri) AS count, httprequest.uri FROM \"waf_logs\" WHERE ("
	query += date
	query += ") AND (action = 'BLOCK') GROUP BY httprequest.uri ORDER BY \"count\" DESC"
	return query
}

func GetAllowedPathCountQuery(date string) string {
	query := "SELECT count(httprequest.uri) AS count, httprequest.uri FROM \"waf_logs\" WHERE ("
	query += date
	query += ") AND (action = 'ALLOW') GROUP BY httprequest.uri ORDER BY \"count\" DESC"
	return query
}

func GetBlockedUrlCountQuery(date string) string {
	query := "WITH dataset AS ( SELECT count(action) AS count, header, action FROM \"waf_logs\" CROSS JOIN UNNEST (httprequest.headers) AS s(header) WHERE ("
	query += date
	query += ") AND (action = 'BLOCK') GROUP BY action, s.header) SELECT count, header.value, action FROM dataset WHERE header.name='Host' ORDER BY count DESC"
	return query
}

func GetAllowedUrlCountQuery(date string) string {
	query := "WITH dataset AS ( SELECT count(action) AS count, header, action FROM \"waf_logs\" CROSS JOIN UNNEST (httprequest.headers) AS s(header) WHERE ("
	query += date
	query += ") AND (action = 'ALLOW') GROUP BY action, s.header) SELECT count, header.value, action FROM dataset WHERE header.name='Host' ORDER BY count DESC"
	return query
}

func GetAllInboundQuery(date string) string {
	query := "SELECT count(timestamp) FROM \"waf_logs\" WHERE ("
	query += date
	query += ")"
	return query
}

func GetRuleAllowQuery(date string) string {
	query := "SELECT count( t.rulegroupid) AS count, t.rulegroupid, t.terminatingrule.ruleid AS TerminatingRuleID, t.nonterminatingmatchingrules FROM \"waf_logs\" CROSS JOIN UNNEST(rulegrouplist) AS t(t) WHERE ("
	query += date
	query += ") AND action = 'ALLOW' AND (t.terminatingrule.ruleid is not null OR CARDINALITY (t.nonterminatingmatchingrules) != 0) GROUP BY action, t.rulegroupid, t.terminatingrule.ruleid, t.nonterminatingmatchingrules ORDER BY count DESC"
	return query
}

func GetRuleBlockQuery(date string) string {
	query := "SELECT count(t.rulegroupid) AS count, t.rulegroupid, t.terminatingrule.ruleid AS TerminatingRuleID, t.nonterminatingmatchingrules FROM \"waf_logs\" CROSS JOIN UNNEST(rulegrouplist) AS t(t) WHERE ("
	query += date
	query += ") AND action = 'BLOCK' AND (t.terminatingrule.ruleid is not null OR CARDINALITY (t.nonterminatingmatchingrules) != 0) GROUP BY action, t.rulegroupid, t.terminatingrule.ruleid, t.nonterminatingmatchingrules ORDER BY count DESC"
	return query
}

func GetCountryInboundQuery(date string) string {
	query := "SELECT count(t.rulegroupid) AS count, httprequest.country FROM \"waf_logs\" CROSS JOIN UNNEST(rulegrouplist) AS t(t) WHERE ("
	query += date
	query += ") AND action = 'ALLOW' AND (t.terminatingrule.ruleid is not null OR CARDINALITY (t.nonterminatingmatchingrules) != 0) GROUP BY httprequest.country ORDER BY count DESC"
	return query
}

func GetDate() string {

	firstday := time.Date(time.Now().Year(), time.Now().Month(), 1, 0, 0, 0, 0, time.Local)
	lastday := firstday.AddDate(0, 0, -1)
	var datequery string
	for i := 0; i < lastday.Day(); i++ {
		if i == 0 {
			datequery += "date = '"
			datequery += strconv.Itoa(lastday.Year()) + "/" + getDateString(int(lastday.Month())) + "/" + getDateString(i+1)
			datequery += "'"
		} else {
			datequery += " or date = '"
			datequery += strconv.Itoa(lastday.Year()) + "/" + getDateString(int(lastday.Month())) + "/" + getDateString(i+1)
			datequery += "'"
		}
	}

	return datequery
}

func getDateString(date int) string {
	if date < 10 {
		return "0" + strconv.Itoa(date)
	} else {
		return strconv.Itoa(date)
	}
}

func GetAccountId(cfg aws.Config) string {
	client := sts.NewFromConfig(cfg)
	input := &sts.GetCallerIdentityInput{}

	req, getaccountiderr := client.GetCallerIdentity(context.TODO(), input)
	check("getaccountiderr", getaccountiderr)

	return *req.Account
}

func check(errorname string, err error) {
	if err != nil {
		log.Printf("%s", errorname)
		log.Fatalln(err.Error())
	}
}

func init() {
	log.Println("start program")
	log.Println(os.Getenv("DATABASE_NAME"))
	log.Println(os.Getenv("WORKGROUP_NAME"))
	log.Println(os.Getenv("BUCKET_NAME"))
}

func main() {
	lambda.Start(analyzer)
}
