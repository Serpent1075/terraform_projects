package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"github.com/aws/aws-lambda-go/events"
	runtime "github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	//	"github.com/aws/aws-sdk-go-v2/service/codebuild"
	//	"github.com/aws/aws-sdk-go-v2/service/codebuild/types"
)

var ccfg aws.Config

type GitEvent struct {
	Url               string   `json:"git_http_url"`
	Obejct_kind       string   `json:"object_kind"`
	Object_attributes []string `json:"object_attributes"`
	Last_Commit       string   `json:"last_commit"`
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

}

func main() {
	runtime.Start(startCodeBuild)
}

func startCodeBuild(ctx context.Context, event events.APIGatewayProxyRequest) {
	gitevent := GitEvent{}
	json.Unmarshal([]byte(event.Body), &gitevent)

	log.Println("Starting")
	log.Println(event.Body)

	//buildclient := codebuild.NewFromConfig(ccfg)

	/*
		getinput := codebuild.StartBuildInput{
			ProjectName: aws.String(""),
			ArtifactsOverride: &types.ProjectArtifacts{
				Type: types.ArtifactsTypeNoArtifacts,
			},
			SecondarySourcesVersionOverride: []types.ProjectSourceVersion{
				SourceIdentifier: aws.String(),

			},
			BuildspecOverride: aws.String(""),
		}
		output, err := buildclient.StartBuild(context.Background(), &getinput)
		if err != nil {
			log.Println(err)
		} else {
			log.Println(output)
		}
	*/
}
