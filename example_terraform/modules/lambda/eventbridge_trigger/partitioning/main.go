package main

import (
	"context"
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

	"github.com/aws/aws-sdk-go-v2/service/sts"
)

func partitioning(ctx context.Context, event events.CloudWatchEvent) {
	cfg, cfgerr := config.LoadDefaultConfig(
		context.Background(),
	)
	check("cfgerr", cfgerr)
	ExecuteAthenaQuery(cfg)
}

func ExecuteAthenaQuery(cfg aws.Config) {
	athenaclient := athena.NewFromConfig(cfg)
	typequery := types.QueryExecutionContext{
		Catalog:  aws.String("AwsDataCatalog"),
		Database: aws.String(os.Getenv("DATABASE_NAME")),
	}

	accountid := GetAccountId(cfg)
	date := GetDate()
	query := "ALTER TABLE waf_logs ADD PARTITION (`date`='" + date + "') LOCATION 's3://" + os.Getenv("BUCKET_NAME") + "/AWSLogs/" + accountid + "/" + date + "'"
	log.Println(query)
	athenaqueryinput := athena.StartQueryExecutionInput{
		QueryString:           aws.String(query),
		QueryExecutionContext: &typequery,
		WorkGroup:             aws.String(os.Getenv("WORKGROUP_NAME")),
	}

	athenaqueryoutput, athenaqueryerr := athenaclient.StartQueryExecution(context.Background(), &athenaqueryinput)
	check("athenaqueryerr", athenaqueryerr)
	log.Println(*athenaqueryoutput.QueryExecutionId)
}

func GetDate() string {
	date := strconv.Itoa(time.Now().Year()) + "/" + getDateString(int(time.Now().Month())) + "/" + getDateString(time.Now().Day())
	return date
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
	lambda.Start(partitioning)
}
