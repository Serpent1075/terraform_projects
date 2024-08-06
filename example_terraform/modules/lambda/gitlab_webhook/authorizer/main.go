package main

import (
	"context"
	"fmt"
	"log"

	"github.com/aws/aws-lambda-go/events"
	runtime "github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
)

var ccfg aws.Config

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
	runtime.Start(verifyToken)
}

func verifyToken(ctx context.Context, event events.APIGatewayCustomAuthorizerRequest) (events.APIGatewayCustomAuthorizerResponse, error) {
	token := event.AuthorizationToken
	expected_token := ""
	if token == expected_token {
		return generatePolicy("user", "Allow", event.MethodArn), nil
	} else {
		return generatePolicy("user", "Deny", event.MethodArn), nil
	}
}

func generatePolicy(principalId, effect, resource string) events.APIGatewayCustomAuthorizerResponse {
	authResponse := events.APIGatewayCustomAuthorizerResponse{PrincipalID: principalId}

	if effect != "" && resource != "" {
		authResponse.PolicyDocument = events.APIGatewayCustomAuthorizerPolicy{
			Version: "2012-10-17",
			Statement: []events.IAMPolicyStatement{
				{
					Action:   []string{"execute-api:Invoke"},
					Effect:   effect,
					Resource: []string{resource},
				},
			},
		}
	}

	// Optional output with custom properties of the String, Number or Boolean type.
	authResponse.Context = map[string]interface{}{
		"stringKey":  "stringval",
		"numberKey":  123,
		"booleanKey": true,
	}
	return authResponse
}
