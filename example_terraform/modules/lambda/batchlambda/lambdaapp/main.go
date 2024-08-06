package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	runtime "github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/batch"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
	secretype "github.com/aws/aws-sdk-go-v2/service/secretsmanager/types"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
)

type Prefix struct {
	Prefix        string `json:"prefix"`
	CFurl         string `json:"cfurl"`
	BuildBehavior string `json:"buildbehavior"`
}

type RDSConfig struct {
	ReaderEndPoint string `json:"psqlreaderendpoint"`
	WriterEndPoint string `json:"psqlwriteerendpoint"`
	UserName       string `json:"username"`
	Port           string `json:"psqlport"`
	DBName         string `json:"dbname"`
}

type SecretValue struct {
	Password string `json:"password"`
}

var readdb *sqlx.DB
var ccfg aws.Config
var prefix Prefix
var rdsconfig RDSConfig
var secretvalue SecretValue
var secretName string = "my/prefix/"

var premiumserviceid string = "serviceid"

func GetSecretValue() {

	client := secretsmanager.NewFromConfig(ccfg)

	input := &secretsmanager.GetSecretValueInput{
		SecretId:     aws.String(secretName),
		VersionStage: aws.String("AWSCURRENT"), // VersionStage defaults to AWSCURRENT if unspecified
	}

	result, err := client.GetSecretValue(context.TODO(), input)
	if err != nil {
		switch err.(type) {
		case *secretype.DecryptionFailure:
			// Secrets Manager can't decrypt the protected secret text using the provided KMS key.
			fmt.Println(err.Error())

		case *secretype.InternalServiceError:
			// An error occurred on the server side.
			fmt.Println(err.Error())

		case *secretype.InvalidParameterException:
			// You provided an invalid value for a parameter.
			fmt.Println(err.Error())

		case *secretype.InvalidRequestException:
			// You provided a parameter value that is not valid for the current state of the resource.
			fmt.Println(err.Error())

		case *secretype.ResourceNotFoundException:
			// We can't find the resource that you asked for.
			fmt.Println(err.Error())
		default:

			fmt.Println(err.Error())
		}

		return
	}

	var secretString string
	if result.SecretString != nil {
		secretString = *result.SecretString
	}
	json.Unmarshal([]byte(secretString), &prefix)
	log.Println(prefix.Prefix)
	log.Println(prefix.BuildBehavior)
	rds_secret_input := &secretsmanager.GetSecretValueInput{
		SecretId:     aws.String(prefix.Prefix + "/" + prefix.BuildBehavior + "/rds/"),
		VersionStage: aws.String("AWSCURRENT"), // VersionStage defaults to AWSCURRENT if unspecified
	}

	rds_secret_result, err := client.GetSecretValue(context.TODO(), rds_secret_input)
	if err != nil {
		switch err.(type) {
		case *secretype.DecryptionFailure:
			// Secrets Manager can't decrypt the protected secret text using the provided KMS key.
			fmt.Println(err.Error())

		case *secretype.InternalServiceError:
			// An error occurred on the server side.
			fmt.Println(err.Error())

		case *secretype.InvalidParameterException:
			// You provided an invalid value for a parameter.
			fmt.Println(err.Error())

		case *secretype.InvalidRequestException:
			// You provided a parameter value that is not valid for the current state of the resource.
			fmt.Println(err.Error())

		case *secretype.ResourceNotFoundException:
			// We can't find the resource that you asked for.
			fmt.Println(err.Error())
		default:

			fmt.Println(err.Error())
		}

		return
	}

	var rds_secret_secretString string
	if rds_secret_result.SecretString != nil {
		rds_secret_secretString = *rds_secret_result.SecretString
	}
	json.Unmarshal([]byte(rds_secret_secretString), &rdsconfig)

	secret_input := &secretsmanager.GetSecretValueInput{
		SecretId:     aws.String(prefix.Prefix + "/" + prefix.BuildBehavior + "/secret/"),
		VersionStage: aws.String("AWSCURRENT"), // VersionStage defaults to AWSCURRENT if unspecified
	}

	secret_result, err := client.GetSecretValue(context.TODO(), secret_input)
	if err != nil {
		switch err.(type) {
		case *secretype.DecryptionFailure:
			// Secrets Manager can't decrypt the protected secret text using the provided KMS key.
			fmt.Println(err.Error())

		case *secretype.InternalServiceError:
			// An error occurred on the server side.
			fmt.Println(err.Error())

		case *secretype.InvalidParameterException:
			// You provided an invalid value for a parameter.
			fmt.Println(err.Error())

		case *secretype.InvalidRequestException:
			// You provided a parameter value that is not valid for the current state of the resource.
			fmt.Println(err.Error())

		case *secretype.ResourceNotFoundException:
			// We can't find the resource that you asked for.
			fmt.Println(err.Error())
		default:

			fmt.Println(err.Error())
		}

		return
	}

	var secret_secretString string
	if rds_secret_result.SecretString != nil {
		secret_secretString = *secret_result.SecretString
	}
	json.Unmarshal([]byte(secret_secretString), &secretvalue)
}

func init() {
	log.Println("init start")

	var err error
	region := "ap-northeast-2"

	//Create a Secrets Manager client
	ccfg, err = config.LoadDefaultConfig(context.TODO(),
		config.WithRegion(region),
	)
	if err != nil {
		// handle error
		fmt.Println(err.Error())
	}
	GetSecretValue()
	ConnectToDB()
}

func main() {
	runtime.Start(submitParameterToBatchJob)
}

func submitParameterToBatchJob(ctx context.Context) {

	//listofcandi := CheckPremiumUser(premiumserviceid)
	candi := "uuidtest1234"
	batchclient := batch.NewFromConfig(ccfg)
	log.Println(prefix.Prefix + "/" + prefix.BuildBehavior + "/secret/")
	for i := 0; i < 10; i++ {
		//for _, candi := range listofcandi {
		submitinput := batch.SubmitJobInput{
			JobDefinition: aws.String(prefix.Prefix + "-batch-job-definition"),
			JobName:       aws.String(prefix.Prefix + "-batch-job"),
			JobQueue:      aws.String(prefix.Prefix + "-batch-job-queue"),
			Parameters: map[string]string{
				"uuid": candi,
			},
		}

		output, err := batchclient.SubmitJob(ctx, &submitinput)
		if err != nil {
			log.Println(err)
		} else {
			log.Println(output.JobId)
		}
	}

}

func ConnectToDB() {
	var readdberr error
	readpsqlInfo := fmt.Sprintf("host=%s port=%s user=%s "+"password=%s dbname=%s sslmode=disable", rdsconfig.ReaderEndPoint, rdsconfig.Port, rdsconfig.UserName, secretvalue.Password, rdsconfig.DBName)
	readdb, readdberr = sqlx.Open("postgres", readpsqlInfo)
	if readdb != nil {
		readdb.SetMaxOpenConns(1000) //최대 커넥션
		readdb.SetMaxIdleConns(100)  //대기 커넥션
	}
	if readdberr != nil {
		fmt.Printf("readdberr: %v", readdberr)
		panic(readdberr)
	} else {
		log.Println("DB connected")
	}
}
