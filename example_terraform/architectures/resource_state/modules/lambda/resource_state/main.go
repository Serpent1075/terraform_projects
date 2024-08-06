package main

import (
	"bytes"
	"context"
	"encoding/csv"
	"io"
	"log"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/cloudfront"
	"github.com/aws/aws-sdk-go-v2/service/cloudwatch"
	"github.com/aws/aws-sdk-go-v2/service/ec2"
	"github.com/aws/aws-sdk-go-v2/service/eks"
	"github.com/aws/aws-sdk-go-v2/service/elasticloadbalancingv2"
	"github.com/aws/aws-sdk-go-v2/service/rds"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/sts"
	"github.com/xuri/excelize/v2"
)

func resource_state(ctx context.Context, event events.CloudWatchEvent) {
	accountlist := ReadAccount()
	//DescribeRecord(context.TODO(), accountlist)
	resultresources := DescribeRecord(context.TODO(), accountlist) //5. API를 통해 aws의 리소스 정보를 가져오는 함수
	title := "resource_state_"
	filename, file := MakeExcelReport(title, resultresources) //6. 5번에서 가져온 리소스 정보를 엑셀로 만드는 함수
	log.Println(filename)
	PutExcelFileToS3(filename, file)
}

func init() { //1. 초기화 함수
	log.Println("start program")
	log.Println(os.Getenv("bucketname"))
}

func main() { //2. 메인 함수
	lambda.Start(resource_state) // resource_state 함수를 람다로 실행
}

var awscfg aws.Config = ReadClientKey() //3. 테스트 계정의 aws 권한을 가져오기
var accountid string = GetAccountId()   //4. 테스트 계정의 aws 계정명 가져오기

type KeyData struct {
	AccessKey string
	SecretKey string
}

func PutExcelFileToS3(filename string, excelfile *excelize.File) {
	buffer, buffererr := excelfile.WriteToBuffer()
	check(buffererr)
	s3client := s3.NewFromConfig(awscfg)
	s3input := s3.PutObjectInput{
		Bucket:              aws.String(os.Getenv("bucketname")),
		Key:                 aws.String("output/resource_state/" + strconv.Itoa(time.Now().Year()) + "/" + strconv.Itoa(int(time.Now().Month())) + "/" + filename),
		ExpectedBucketOwner: aws.String(accountid),
		Body:                bytes.NewReader(buffer.Bytes()),
	}
	_, outputerr := s3client.PutObject(context.Background(), &s3input)
	check(outputerr)

}

func DescribeRecord(ctx context.Context, accountids []Account) []*ResultResource {

	for i, account := range accountids { // 계정별 키 정보를 가져오는 루틴

		s3client := s3.NewFromConfig(awscfg)
		s3input := s3.GetObjectInput{
			Bucket:              aws.String(os.Getenv("bucketname")),
			Key:                 aws.String("Automation-Key/" + account.Filename),
			ExpectedBucketOwner: aws.String(accountid),
		}
		s3output, outputerr := s3client.GetObject(context.TODO(), &s3input) // s3에서 Automation Key를 가져오는 api 요청
		if outputerr != nil {
			log.Fatalf("failed to get Automation-Key object in bucket, %v", outputerr)
		}
		keydata, readcsverr := ReadCsv(s3output.Body) // s3에서 csv에 담긴 Automation Key 정보를 가져와서 코드에서 쓸수 있도록 읽어들이는 함수
		check(readcsverr)

		cfg, err := config.LoadDefaultConfig(
			context.TODO(),
			config.WithCredentialsProvider(
				credentials.NewStaticCredentialsProvider(keydata[1][0], keydata[1][1], ""),
			),
		)
		check(err)
		accountids[i].AwsCfg = cfg
	}

	var resultresources []*ResultResource = make([]*ResultResource, 0)

	for _, account := range accountids { // 가져온 계정별 키 정보를 이용하여 각 계정의 리소스 정보를 가져오는 루틴

		log.Println(account.AccountName)
		ec2ridatas := GetEC2RIData(account.AwsCfg)                                           // 예약 인스턴스 정보를 가져옴
		ec2datas, ec2runningcount, ec2stoppedcount := GetEC2Data(account.AwsCfg, ec2ridatas) // EC2 정보를 가져옴

		vpcdatas := GetVPCData(account.AwsCfg)                 // VPC 정보를 가져옴
		subnetdatas := GetSubnetData(account.AwsCfg)           // VPC 서브넷 정보를 가져옴
		vpndatas := GetVPNData(account.AwsCfg)                 // VPN 정보를 가져옴
		eipdatas := GetEIPData(account.AwsCfg)                 // EIP 정보를 가져옴
		ebsdatas := GetEBSData(account.AwsCfg)                 // EBS 정보를 가져옴
		sgdatas := GetSecurityGroupData(account.AwsCfg)        // 보안그룹 정보를 가져옴
		natgatewaydatas := GetNatGateway(account.AwsCfg)       // NAT Gateway 정보를 가져옴
		lbdatas := GetLoadBalancer(account.AwsCfg)             // 로드밸런서 정보를 가져옴
		targetgroupdatas := GetTargetGroupData(account.AwsCfg) // 타겟 그룹 정보를 가져옴
		//var lbcount *LBCountData
		rdsridatas := GetRDSRIData(account.AwsCfg)                       //RDS 예약 노드 정보를 가져옴
		clusterdatas, rdsdatas := GetRDSData(account.AwsCfg, rdsridatas) // RDS 정보를 가져옴
		s3datas := GetS3Data(account.AwsCfg)                             // S3 정보를 가져옴
		clusternames := GetEKSCluster(account.AwsCfg)                    // EKS Cluster 정보를 가져옴
		eksdatas := GetEKSNodeGroupName(account.AwsCfg, clusternames)    // 각 클러스터의 EKS 노드 그룹 이름 정보를 가져옴
		GetEKSNodeGroup(account.AwsCfg, eksdatas)                        // 각 노드그룹 정보를 가져옴
		cwalarmdatas := GetCloudWatchAlarmData(account.AwsCfg)           // Cloudwatch 알람 정보를 가져옴
		cfdatas := GetCloudfrontData(account.AwsCfg)                     // Cloudfront 정보를 가져옴

		/*
			if ec2datas != nil {
				fmt.Println(ec2datas)
			}
			if vpndatas != nil {
				fmt.Println(vpndatas)
			}
			if clusterdatas != nil {
				fmt.Println(clusterdatas)
			}
			if rdsdatas != nil {
				fmt.Println(rdsdatas)
			}
			if natgatewaydatas != nil {
				fmt.Println(natgatewaydatas)
			}

			if lbdatas != nil {
				lbcount = LBCount(lbdatas)
			}
		*/
		resultresource := ResultResource{ // 결과 객체에 가져온 정보들을 저장함
			AccountID:             account.AccountID,
			AccountName:           account.AccountName,
			EC2:                   ec2datas,
			EC2Running:            ec2runningcount,
			EC2Stopped:            ec2stoppedcount,
			VPCData:               vpcdatas,
			SubnetData:            subnetdatas,
			VPN:                   vpndatas,
			ClusterData:           clusterdatas,
			RDSData:               rdsdatas,
			LB:                    lbdatas,
			TargetGroupData:       targetgroupdatas,
			EIPData:               eipdatas,
			EBSData:               ebsdatas,
			SecurityGroupRuleData: sgdatas,
			NatGatewayData:        natgatewaydatas,
			S3Data:                s3datas,
			EKSData:               eksdatas,
			CloudwatchAlarmData:   cwalarmdatas,
			CFData:                cfdatas,
		}

		if strings.TrimSpace(resultresource.AccountID) != "" {
			resultresources = append(resultresources, &resultresource)
		}

	}

	return resultresources
}

func LBCount(lbdatas []*LoadBalancerData) *LBCountData {
	var lbcount LBCountData

	for _, lbdata := range lbdatas {
		if lbdata.PrdDev == "Dev" {
			if lbdata.InExternal == "internal" {
				if lbdata.Type == "application" {
					lbcount.DevIntAlb++
				} else {
					lbcount.DevIntNlb++
				}
			} else {
				if lbdata.Type == "application" {
					lbcount.DevExtAlb++
				} else {
					lbcount.DevExtNlb++
				}
			}
		} else {
			if lbdata.InExternal == "internal" {
				if lbdata.Type == "application" {
					lbcount.PrdIntAlb++
				} else {
					lbcount.PrdIntNlb++
				}
			} else {
				if lbdata.Type == "application" {
					lbcount.PrdExtAlb++
				} else {
					lbcount.PrdExtNlb++
				}
			}
		}
	}

	return &lbcount
}

func GetS3Data(cfg aws.Config) []*S3Data {
	s3client := s3.NewFromConfig(cfg)                                       // aws.Config라는 각 AWS 계정에 대한 credential 정보가 저장된 객체를 이용하여 s3객체에 부여함으로써 해당 계정의 s3에 접근 권한을 가진 객체를 생성
	s3input := s3.ListBucketsInput{}                                        // s3의 ListBucket API를 사용하기 위해 조건을 넣을 수 있는 객체 생성 (조건 없이 모든 객체를 가져와야하므로 조건을 넣지 않음)
	s3output, s3err := s3client.ListBuckets(context.Background(), &s3input) // list bucket을 통해 계정에 속한 버킷들 정보를 가져옴
	check(s3err)

	var s3bucketdatas []*S3Data = make([]*S3Data, 0) // 복수의 버킷정보를 담을 수 있는 배열 생성

	for _, data := range s3output.Buckets { // 가져온 버킷정보들을 하나하나 제어할 수 있는 반복문 생성
		s3bucketdata := S3Data{ // 아래에 type S3Data struct라고 생성한 S3Data라는 객체에 가져온 버킷 정보를 담는 변수 생성
			Name:        *data.Name,                 // 버킷 이름 정보를 내 코드에서 사용할 수 있도록 S3Data 객체의 Name이라는 공간에 주입
			CreatedDate: data.CreationDate.String(), // 버킷 생성날짜 정보를 내 코드에서 사용할 수 있도록 S3Data 객체의 CreatedDate라는 공간에 주입
		}

		s3bucketdatas = append(s3bucketdatas, &s3bucketdata) // 버킷정보 결과를 저장하기 위해 위에 생성한 s3bucketdatas 배열 정보에 객체를 주입
	}
	return s3bucketdatas //반복문으로 가져온 모든 s3정보를 배열에 담아 리턴 시킴
}

func GetEBSData(cfg aws.Config) []*EBSData { // EBS 정보를 가져오기 위한 API 요청
	ebsclient := ec2.NewFromConfig(cfg)
	ebsinput := ec2.DescribeVolumesInput{}
	ebsoutput, ebserr := ebsclient.DescribeVolumes(context.Background(), &ebsinput)
	check(ebserr)

	var ebsdatas []*EBSData = make([]*EBSData, 0)

	for _, data := range ebsoutput.Volumes {
		ebsdata := EBSData{
			ID:    *data.VolumeId,
			Type:  string(data.VolumeType),
			Size:  *data.Size,
			State: string(data.State),
		}

		if data.Iops != nil {
			ebsdata.IOPS = *data.Iops
		}

		for _, tag := range data.Tags {
			if *tag.Key == "Name" {
				ebsdata.Name = *tag.Value
				break
			}
		}
		ebsdatas = append(ebsdatas, &ebsdata)
	}
	return ebsdatas
}

func GetTargetGroupData(cfg aws.Config) []*TargetGroupData { // 타겟 그룹 정보를 가져오기 위한 API 요청

	targetclient := elasticloadbalancingv2.NewFromConfig(cfg)
	targetinput := elasticloadbalancingv2.DescribeTargetGroupsInput{}
	targetoutput, targetoutputerr := targetclient.DescribeTargetGroups(context.Background(), &targetinput)
	check(targetoutputerr)

	var targetdatas []*TargetGroupData = make([]*TargetGroupData, 0)

	for _, data := range targetoutput.TargetGroups {
		tgdata := TargetGroupData{
			Name:      *data.TargetGroupName,
			VPCId:     *data.VpcId,
			Protocol:  string(data.Protocol),
			Port:      *data.Port,
			TargetARN: *data.TargetGroupArn,
			LBARN:     data.LoadBalancerArns,
		}
		/* 각 리스너 정보 및 각 타겟그룹 정보를 긁어오는 코드이지만 api 요청이 너무 많이 이루어져 aws측에서 막아버려, 사용이 불가
		tgdata.ListenerRules = make([]ListenerRule, 0)
		tgdata.TargetIDs = make([]string, 0)

		if strings.ToLower(os.Getenv("GetListenerRuleData")) == "yes" && len(targetoutput.TargetGroups) < 20 {
			for _, lbarn := range data.LoadBalancerArns {

				listenerinput := elasticloadbalancingv2.DescribeListenersInput{
					LoadBalancerArn: aws.String(lbarn),
				}
				listeneroutput, listeneroutputerr := targetclient.DescribeListeners(context.Background(), &listenerinput)
				check(listeneroutputerr)

				for _, listenlbarn := range listeneroutput.Listeners {

					if *listenlbarn.LoadBalancerArn == lbarn {
						rulesinput := elasticloadbalancingv2.DescribeRulesInput{
							ListenerArn: listenlbarn.ListenerArn,
						}
						rulesoutput, rulesoutputerr := targetclient.DescribeRules(context.Background(), &rulesinput)
						check(rulesoutputerr)
						time.Sleep(1000)

						for _, rule := range rulesoutput.Rules {
							for _, action := range rule.Actions {
								if action.TargetGroupArn != nil {
									if *action.TargetGroupArn == *data.TargetGroupArn {
										var listenerrule ListenerRule

										listenerrule.Condition = make([]Condition, 0)
										listenerrule.ListenerARN = *listenlbarn.ListenerArn

										if action.ForwardConfig != nil {
											if action.ForwardConfig.TargetGroupStickinessConfig != nil {
												if action.ForwardConfig.TargetGroupStickinessConfig.Enabled != nil {
													listenerrule.StickyEnabled = *action.ForwardConfig.TargetGroupStickinessConfig.Enabled
												}
											}

										}

										for _, condition := range rule.Conditions {

											if condition.HostHeaderConfig != nil {
												for _, value := range condition.HostHeaderConfig.Values {
													tmpcondition := Condition{
														Field: *condition.Field,
														Value: value,
													}
													listenerrule.Condition = append(listenerrule.Condition, tmpcondition)
												}
											}

										}

										tgdata.ListenerRules = append(tgdata.ListenerRules, listenerrule)
									}
								}
							}
						}

					}
				}
			}
			gettargethealthinput := elasticloadbalancingv2.DescribeTargetHealthInput{
				TargetGroupArn: data.TargetGroupArn,
			}
			targetoutput, targetoutputerr := targetclient.DescribeTargetHealth(context.Background(), &gettargethealthinput)
			check(targetoutputerr)
			time.Sleep(1000)

			for _, targethealth := range targetoutput.TargetHealthDescriptions {
				tgdata.TargetIDs = append(tgdata.TargetIDs, *targethealth.Target.Id)
			}

			if *data.HealthCheckEnabled {

				tgdata.HealthCheckProtocol = string(data.HealthCheckProtocol)
				tgdata.HealthCheckPort = *data.HealthCheckPort

				if data.HealthCheckPath != nil {
					tgdata.HealthCheckPath = *data.HealthCheckPath
				} else {
					tgdata.HealthCheckPath = ""
				}
				tgdata.HealthCheckTimeoutSeconds = *data.HealthCheckTimeoutSeconds
				tgdata.HealthCheckThresholdCount = *data.HealthyThresholdCount
				tgdata.UnhealthyThresholdCount = *data.UnhealthyThresholdCount
			}
		}
		*/
		targetdatas = append(targetdatas, &tgdata)
	}
	return targetdatas
}

func GetLoadBalancer(cfg aws.Config) []*LoadBalancerData { // LB 정보를 가져오기 위한 API 요청
	lbclient := elasticloadbalancingv2.NewFromConfig(cfg)
	lbinput := elasticloadbalancingv2.DescribeLoadBalancersInput{}
	lboutput, lberr := lbclient.DescribeLoadBalancers(context.Background(), &lbinput)
	check(lberr)

	var lbdatas []*LoadBalancerData = make([]*LoadBalancerData, 0)

	for _, data := range lboutput.LoadBalancers {
		lbname := *data.LoadBalancerName
		var lbprddev string
		if strings.Contains(strings.ToLower(lbname), "dev") {
			lbprddev = "Dev"
		} else {
			lbprddev = "Prod"
		}

		lbdata := LoadBalancerData{
			Name:       *data.LoadBalancerName,
			Type:       string(data.Type),
			InExternal: string(data.Scheme),
			PrdDev:     lbprddev,
		}
		lbdatas = append(lbdatas, &lbdata)
	}
	return lbdatas
}

func GetNatGateway(cfg aws.Config) []*NatGatewayData { // NAT Gateway 정보를 가져오기 위한 API 요청
	ec2client := ec2.NewFromConfig(cfg)
	natgatewayinput := ec2.DescribeNatGatewaysInput{}
	natgatewayoutput, natgatewayerr := ec2client.DescribeNatGateways(context.Background(), &natgatewayinput)
	check(natgatewayerr)

	var natgatewaydatas []*NatGatewayData = make([]*NatGatewayData, 0)
	for _, data := range natgatewayoutput.NatGateways {
		natgatewaydata := NatGatewayData{
			Name: *data.Tags[0].Value,
		}
		natgatewaydatas = append(natgatewaydatas, &natgatewaydata)
	}
	return natgatewaydatas
}

func GetVPNData(cfg aws.Config) []*VPNData { // VPN 정보를 가져오기 위한 API 요청
	ec2client := ec2.NewFromConfig(cfg)
	vpninput := ec2.DescribeVpnConnectionsInput{}
	vpnoutput, vpnerr := ec2client.DescribeVpnConnections(context.Background(), &vpninput)
	check(vpnerr)

	var vpndatas []*VPNData = make([]*VPNData, 0)
	for _, data := range vpnoutput.VpnConnections {
		vpndata := VPNData{
			Name: *data.Tags[0].Value,
		}
		vpndatas = append(vpndatas, &vpndata)
	}
	return vpndatas
}

func GetCloudWatchAlarmData(cfg aws.Config) []*AlarmData { // Cloudwatch 알람 데이터를 가져오기 위한 API 요청
	cwclient := cloudwatch.NewFromConfig(cfg)
	cwinput := cloudwatch.DescribeAlarmsInput{}
	cwoutput, cwoutputerr := cwclient.DescribeAlarms(context.Background(), &cwinput)
	check(cwoutputerr)
	var cwalarmdatas []*AlarmData = make([]*AlarmData, 0)
	for _, data := range cwoutput.MetricAlarms {

		var alarmactions []string = make([]string, 0)
		var dimensionames []string = make([]string, 0)
		var dimensionvalues []string = make([]string, 0)
		var datapoint int32
		var treatmissingdata string
		for _, action := range data.AlarmActions {
			alarmactions = append(alarmactions, action)
			break
		}

		for _, dimension := range data.Dimensions {
			dimensionames = append(dimensionames, string(*dimension.Name))
			dimensionvalues = append(dimensionvalues, string(*dimension.Value))
		}

		if data.DatapointsToAlarm != nil {
			datapoint = *data.DatapointsToAlarm
		} else {
			datapoint = 0
		}

		if data.TreatMissingData != nil {
			treatmissingdata = *data.TreatMissingData
		} else {
			treatmissingdata = ""
		}

		cwalarmdata := AlarmData{
			Eabled:             *data.ActionsEnabled,
			Actions:            alarmactions,
			Name:               *data.AlarmName,
			ComparisonOperator: string(data.ComparisonOperator),
			DatapointsToAlarm:  datapoint,
			DimensionName:      dimensionames,
			DimensionValue:     dimensionvalues,
			EvaluationPeriods:  *data.EvaluationPeriods,
			Period:             *data.Period,
			Statistic:          string(data.Statistic),
			Threshold:          *data.Threshold,
			TreatMissingData:   treatmissingdata,
		}
		cwalarmdatas = append(cwalarmdatas, &cwalarmdata)
	}
	return cwalarmdatas
}

func GetCloudfrontData(cfg aws.Config) []*CFData { // Cloudfront 정보를 가져오기 위한 API 요청
	cfclient := cloudfront.NewFromConfig(cfg)
	cfinput := cloudfront.ListDistributionsInput{}
	cfoutput, cfoutputerr := cfclient.ListDistributions(context.Background(), &cfinput)
	check(cfoutputerr)

	var cfdatas []*CFData = make([]*CFData, 0)

	for _, data := range cfoutput.DistributionList.Items {
		var domainname string
		for i, item := range data.Origins.Items {
			if i == 0 {
				domainname += *item.DomainName
			} else {
				domainname += ", "
				domainname += *item.DomainName
			}
		}

		cfdata := CFData{
			ID:               *data.Id,
			OriginDomainName: domainname,
			Enabled:          *data.Enabled,
			DomainName:       *data.DomainName,
		}
		cfdatas = append(cfdatas, &cfdata)
	}
	return cfdatas
}

func GetVPCData(cfg aws.Config) []*VPCData { // VPC 정보를 가져오기 위한 API 요청
	vpcclient := ec2.NewFromConfig(cfg)
	vpcintput := ec2.DescribeVpcsInput{}
	vpcoutput, vpcoutputerr := vpcclient.DescribeVpcs(context.Background(), &vpcintput)

	var vpcdatas []*VPCData = make([]*VPCData, 0)

	check(vpcoutputerr)
	for _, data := range vpcoutput.Vpcs {
		var name string
		for _, tag := range data.Tags {
			if *tag.Key == "Name" {
				name = *tag.Value
				break
			}
		}
		vpcdata := VPCData{
			Id:   *data.VpcId,
			Name: name,
			Cidr: *data.CidrBlock,
		}
		vpcdatas = append(vpcdatas, &vpcdata)
	}
	return vpcdatas
}

func GetSubnetData(cfg aws.Config) []*SubnetData { // 서브넷 정보를 가져오기 위한 API 요청
	vpcclient := ec2.NewFromConfig(cfg)
	var subnetdatas []*SubnetData = make([]*SubnetData, 0)
	subnetintput := ec2.DescribeSubnetsInput{}
	subnetoutput, subnetoutputerr := vpcclient.DescribeSubnets(context.Background(), &subnetintput)
	check(subnetoutputerr)
	for _, data := range subnetoutput.Subnets {
		var name string
		for _, tag := range data.Tags {
			if *tag.Key == "Name" {
				name = *tag.Value
				break
			}
		}
		subnetdata := SubnetData{
			VPCId:    *data.VpcId,
			SubnetId: *data.SubnetId,
			Name:     name,
			Cidr:     *data.CidrBlock,
		}
		subnetdatas = append(subnetdatas, &subnetdata)
	}
	SortBySubnetCidr(subnetdatas) // API요청으로 가져온 서브넷들을 서브넷 순서로 정렬
	return subnetdatas
}

func GetRDSData(cfg aws.Config, ridatas []*RDSRIData) ([]*ClusterData, []*RDSData) { // RDS 정보를 가져오기 위한 API 요청
	rdsclient := rds.NewFromConfig(cfg)
	rdsclusterinput := rds.DescribeDBClustersInput{}
	rdsclusteroutput, rdsclusteroutputerr := rdsclient.DescribeDBClusters(context.Background(), &rdsclusterinput)
	check(rdsclusteroutputerr)
	rdsinstanceinput := rds.DescribeDBInstancesInput{}
	rdsinstanceoutput, rdsinstanceoutputerr := rdsclient.DescribeDBInstances(context.Background(), &rdsinstanceinput)
	check(rdsinstanceoutputerr)
	var clusterdatas []*ClusterData = make([]*ClusterData, 0)

	for _, data := range rdsclusteroutput.DBClusters {
		var instancedata []RDSData = make([]RDSData, 0)
		for _, member := range data.DBClusterMembers {
			rdsdata := RDSData{
				Identifier: *member.DBInstanceIdentifier,
			}
			instancedata = append(instancedata, rdsdata)
		}
		clusterdata := ClusterData{
			Identifier:     *data.DBClusterIdentifier,
			Engine:         *data.Engine,
			EngineVersion:  *data.EngineVersion,
			Status:         *data.Status,
			EndPoint:       *data.Endpoint,
			ReaderEndpoint: *data.ReaderEndpoint,
			MultiAZ:        *data.MultiAZ,
			RDSData:        instancedata,
			Port:           strconv.Itoa(int(*data.Port)),
		}

		for _, tag := range data.TagList {
			tmp := strings.ReplaceAll(strings.ToLower(*tag.Key), " ", "")

			if tmp == "usage" {
				clusterdata.Usage = *tag.Value
			}
			if tmp == "cname" {
				clusterdata.CName = *tag.Value
			}
			if tmp == "dbsafer" {
				clusterdata.DBSafer = *tag.Value
			}

		}
		clusterdatas = append(clusterdatas, &clusterdata)
	}

	var rdsdatas []*RDSData = make([]*RDSData, 0)
	for _, data := range rdsinstanceoutput.DBInstances {
		var added bool = false
		for i, cluster := range clusterdatas {
			for j, member := range cluster.RDSData {

				if member.Identifier == *data.DBInstanceIdentifier {
					//fmt.Printf("member %s\n", member.Identifier)
					//fmt.Printf("cluster data!@# %s\n", *data.DBInstanceIdentifier)

					rdsdata := RDSData{
						Identifier:       *data.DBInstanceIdentifier,
						Engine:           *data.Engine,
						EngineVersion:    *data.EngineVersion,
						MultiAZ:          *data.MultiAZ,
						StorageType:      *data.StorageType,
						InstanceClass:    *data.DBInstanceClass,
						InstancePort:     *data.Endpoint.Port,
						AllocatedStorage: *data.AllocatedStorage,
					}

					if data.Endpoint != nil {
						rdsdata.EndpointAddress = *data.Endpoint.Address
					}

					for _, tag := range data.TagList {
						tmp := strings.ReplaceAll(strings.ToLower(*tag.Key), " ", "")
						if tmp == "usage" {
							rdsdata.Usage = *tag.Value
						}
						if tmp == "cname" {
							rdsdata.CName = *tag.Value
						}
						if tmp == "dbsafer" {
							rdsdata.DBSafer = *tag.Value
						}
						if tmp == "leaseid" {
							for _, ridata := range ridatas {
								if strings.Contains(*tag.Value, ridata.LeaseId) {
									rdsdata.RDSRIData = append(rdsdata.RDSRIData, ridata)
								}
							}
						}
					}

					clusterdatas[i].RDSData[j] = rdsdata
					added = true
					break
				}
			}
		}

		if !added {
			rdsdata := RDSData{
				Identifier:       *data.DBInstanceIdentifier,
				Engine:           *data.Engine,
				EngineVersion:    *data.EngineVersion,
				MultiAZ:          *data.MultiAZ,
				StorageType:      *data.StorageType,
				InstanceClass:    *data.DBInstanceClass,
				InstancePort:     *data.Endpoint.Port,
				AllocatedStorage: *data.AllocatedStorage,
			}
			if data.Endpoint != nil {
				rdsdata.EndpointAddress = *data.Endpoint.Address
			}
			for _, tag := range data.TagList {
				tmp := strings.ReplaceAll(strings.ToLower(*tag.Key), " ", "")
				if tmp == "usage" {
					rdsdata.Usage = *tag.Value
				}
				if tmp == "cname" {
					rdsdata.CName = *tag.Value
				}
				if tmp == "dbsafer" {
					rdsdata.DBSafer = *tag.Value
				}
				if tmp == "leaseid" {
					for _, ridata := range ridatas {
						if strings.Contains(*tag.Value, ridata.LeaseId) {
							rdsdata.RDSRIData = append(rdsdata.RDSRIData, ridata)
						}
					}
				}
			}
			rdsdatas = append(rdsdatas, &rdsdata)
		}
	}

	return clusterdatas, rdsdatas
}

func GetRDSRIData(cfg aws.Config) []*RDSRIData { // RDS RI 정보를 가져오기 위한 API 요청
	riclient := rds.NewFromConfig(cfg)
	riinput := rds.DescribeReservedDBInstancesInput{}
	rioutput, rioutputerr := riclient.DescribeReservedDBInstances(context.Background(), &riinput)
	check(rioutputerr)
	var ridatas []*RDSRIData = make([]*RDSRIData, 0)
	loc, err := time.LoadLocation("Asia/Seoul")
	if err != nil {
		panic(err)
	}

	for _, data := range rioutput.ReservedDBInstances {

		var endtime time.Time
		if *data.Duration/60/60/24 == 365 {
			endtime = data.StartTime.AddDate(1, 0, 0).In(loc)
		} else {
			endtime = data.StartTime.AddDate(1, 0, 0).In(loc)
		}

		ridata := RDSRIData{
			LeaseId:                       *data.LeaseId,
			DBInstanceClass:               *data.DBInstanceClass,
			Term:                          *data.Duration / 60 / 60 / 24,
			MultiAZ:                       *data.MultiAZ,
			DBInstanceCount:               *data.DBInstanceCount,
			OfferingType:                  *data.OfferingType,
			ProductDescription:            *data.ProductDescription,
			ReservedDBInstanceId:          *data.ReservedDBInstanceId,
			ReservedDBInstancesOfferingId: *data.ReservedDBInstancesOfferingId,
			StartTime:                     *data.StartTime,
			EndTime:                       endtime,
			State:                         *data.State,
		}
		ridatas = append(ridatas, &ridata)
	}
	return ridatas
}

func GetEIPData(cfg aws.Config) []*EIPData { // EIP 정보를 가져오기 위한 API 요청
	ec2client := ec2.NewFromConfig(cfg)
	eipinput := ec2.DescribeAddressesInput{}
	eipoutput, eiperr := ec2client.DescribeAddresses(context.Background(), &eipinput)
	check(eiperr)

	var eipdatas []*EIPData = make([]*EIPData, 0)

	for _, data := range eipoutput.Addresses {
		var eipdata EIPData
		eipdata.IPAddress = *data.PublicIp
		if data.AssociationId != nil {
			eipdata.AssociationId = *data.AssociationId
		} else {
			eipdata.AssociationId = "not using"
		}
		eipdatas = append(eipdatas, &eipdata)
	}
	return eipdatas
}

func GetSecurityGroupData(cfg aws.Config) []*SecurityGroupRuleData { // 보안그룹 정보를 가져오기 위한 API 요청
	ec2client := ec2.NewFromConfig(cfg)
	sgruleinput := ec2.DescribeSecurityGroupRulesInput{}
	sgruleoutput, sgruleerr := ec2client.DescribeSecurityGroupRules(context.Background(), &sgruleinput)
	check(sgruleerr)
	var sgdatas []*SecurityGroupRuleData = make([]*SecurityGroupRuleData, 0)
	for _, sgrule := range sgruleoutput.SecurityGroupRules {
		sgdata := SecurityGroupRuleData{
			GroupID: *sgrule.GroupId,
			RuleID:  *sgrule.SecurityGroupRuleId,
		}

		if *sgrule.IpProtocol == "-1" {
			sgdata.Protocol = "all"
		} else {
			sgdata.Protocol = *sgrule.IpProtocol
		}

		if sgrule.CidrIpv4 != nil {
			sgdata.SrcAddr = *sgrule.CidrIpv4
		} else if sgrule.ReferencedGroupInfo != nil {
			sgdata.SrcAddr = *sgrule.ReferencedGroupInfo.GroupId
		} else if sgrule.CidrIpv6 != nil {
			sgdata.SrcAddr = *sgrule.CidrIpv6
		} else {
			sgdata.SrcAddr = "unknown"
		}

		if *sgrule.FromPort == *sgrule.ToPort {
			if *sgrule.FromPort == -1 {
				sgdata.Port = "all"
			} else {
				sgdata.Port = Int32ToString(sgrule.FromPort)
			}
		} else {
			sgdata.Port = Int32ToString(sgrule.FromPort) + " - " + Int32ToString(sgrule.ToPort)
		}

		if sgrule.Description != nil {
			sgdata.Description = *sgrule.Description
		}

		for _, tag := range sgrule.Tags {
			if *tag.Key == "Name" {
				sgdata.GroupName = *tag.Value
			}
		}
		if *sgrule.IsEgress {
			sgdata.InOutbound = "Outbound"
		} else {
			sgdata.InOutbound = "Inbound"
		}

		sgdatas = append(sgdatas, &sgdata)
	}
	SortByGIDandRuleId(sgdatas)
	return sgdatas
}

func GetEKSNodeGroup(cfg aws.Config, clustersdata []*EKSData) { // 이름을 기반으로 EKS 노드그룹 정보를 가져오기 위한 API 요청
	eksclient := eks.NewFromConfig(cfg)
	for _, data := range clustersdata {
		for i, nodedata := range data.NodeGroupData {
			eksinput := eks.DescribeNodegroupInput{
				ClusterName:   aws.String(data.ClusterName),
				NodegroupName: aws.String(nodedata.NodeGroupName),
			}
			eksoutput, ekserr := eksclient.DescribeNodegroup(context.Background(), &eksinput)
			check(ekserr)
			data.NodeGroupData[i].Version = *eksoutput.Nodegroup.Version
			data.NodeGroupData[i].InstanceTypes = eksoutput.Nodegroup.InstanceTypes
			data.NodeGroupData[i].DiskSize = *eksoutput.Nodegroup.DiskSize
			data.NodeGroupData[i].Min = *eksoutput.Nodegroup.ScalingConfig.MinSize
			data.NodeGroupData[i].Max = *eksoutput.Nodegroup.ScalingConfig.MaxSize
		}
	}
}

func GetEKSNodeGroupName(cfg aws.Config, clustername []string) []*EKSData { // EKS 노드그룹 이름을 가져오기 위한 API 요청
	eksclient := eks.NewFromConfig(cfg)
	var clustersdata []*EKSData = make([]*EKSData, 0)
	for _, data := range clustername {

		eksinput := eks.ListNodegroupsInput{
			ClusterName: aws.String(data),
		}
		eksoutput, ekserr := eksclient.ListNodegroups(context.Background(), &eksinput)
		check(ekserr)
		var nodegroupsdata []*NodeGroupData = make([]*NodeGroupData, 0)
		for _, nodegroup := range eksoutput.Nodegroups {
			nodegroupdata := NodeGroupData{
				NodeGroupName: nodegroup,
			}
			nodegroupsdata = append(nodegroupsdata, &nodegroupdata)
		}

		clusterdata := EKSData{
			ClusterName:   *aws.String(data),
			NodeGroupData: nodegroupsdata,
		}
		clustersdata = append(clustersdata, &clusterdata)
	}

	return clustersdata
}

func GetEKSCluster(cfg aws.Config) []string { // EKS 클러스터 정보를 가져오기 위한 API 요청
	eksclient := eks.NewFromConfig(cfg)
	eksinput := eks.ListClustersInput{}
	eksoutput, ekserr := eksclient.ListClusters(context.Background(), &eksinput)
	check(ekserr)

	return eksoutput.Clusters
}

func SortByGIDandRuleId(sgdatas []*SecurityGroupRuleData) { // SG ID순으로 정렬
	sort.Slice(sgdatas, func(i, j int) bool {
		if sgdatas[i].GroupID != sgdatas[j].GroupID {
			return sgdatas[i].GroupID < sgdatas[j].GroupID
		}
		if sgdatas[i].InOutbound != sgdatas[j].InOutbound {
			return sgdatas[i].InOutbound < sgdatas[j].InOutbound
		}
		return sgdatas[i].RuleID < sgdatas[j].RuleID

	})
}

func SortBySubnetCidr(subnetdatas []*SubnetData) { // Cidr 순서로 정렬
	sort.Slice(subnetdatas, func(i, j int) bool {
		return subnetdatas[i].Cidr < subnetdatas[j].Cidr
	})
}

func toChar(i int) rune { // 숫자를 알파벳으로 변형
	return rune('A' - 1 + i)
}

func Int32ToString(n *int32) string { // int32 타입을 String 타입으로 변환
	buf := [11]byte{}
	pos := len(buf)
	i := int64(*n)
	signed := i < 0
	if signed {
		i = -i
	}
	for {
		pos--
		buf[pos], i = '0'+byte(i%10), i/10
		if i == 0 {
			if signed {
				pos--
				buf[pos] = '-'
			}
			return string(buf[pos:])
		}
	}
}

func GetEC2Data(cfg aws.Config, ridatas []*RIData) ([]*EC2Data, int, int) { //  EC2 Data API 요청
	ec2client := ec2.NewFromConfig(cfg)                                         // API 요청을 위한 객체
	ec2input := ec2.DescribeInstancesInput{}                                    //  API 요청 시 조건을 담는 객체
	ec2output, ec2err := ec2client.DescribeInstances(context.TODO(), &ec2input) // API 요청
	check(ec2err)
	var ec2datas []*EC2Data = make([]*EC2Data, 0)   // 결과 저장을 위한 객체 배열
	var ec2runningcount, ec2stoppedcount int = 0, 0 // 운영 중, 중지 중인 인스턴스 수
	for _, data := range ec2output.Reservations {   // 인스턴스 리스트 결과값을 반복분으로 필요한 부분을 결과 객체에 저장

		if len(data.Instances) == 1 {
			if *data.Instances[0].State.Code == 16 {
				ec2runningcount++
			} else if *data.Instances[0].State.Code == 80 || *data.Instances[0].State.Code == 64 {
				ec2stoppedcount++
			}
			if *data.Instances[0].State.Code != 48 {

				ec2data := EC2Data{
					InstanceId:   *data.Instances[0].InstanceId,
					PrivateIP:    *data.Instances[0].PrivateIpAddress,
					InstanceType: string(data.Instances[0].InstanceType),
					Status:       string(data.Instances[0].State.Name),
				}

				for _, tag := range data.Instances[0].Tags {
					tmp := strings.ReplaceAll(strings.ToLower(*tag.Key), " ", "")

					if tmp == "name" {
						ec2data.InstanceName = *tag.Value
					}

					if tmp == "usage" {
						ec2data.Usage = *tag.Value
					}

					if tmp == "hostname" {
						ec2data.Hostname = *tag.Value
					}

					if tmp == "osversion" {
						ec2data.OSVersion = *tag.Value
					}
					if tmp == "site" {
						ec2data.Site = *tag.Value
					}

					if tmp == "dbsafer" {
						ec2data.DBSafer = *tag.Value
					}
					if tmp == "riid" {
						for _, ridata := range ridatas {
							if strings.Contains(*tag.Value, ridata.RIID) {
								ec2data.RIData = append(ec2data.RIData, ridata)
							}
						}
					}
				}
				ec2datas = append(ec2datas, &ec2data)
			}
		} else {

			for _, data2 := range data.Instances {
				if *data2.State.Code == 16 {
					ec2runningcount++
				} else if *data2.State.Code == 80 || *data2.State.Code == 64 {
					ec2stoppedcount++
				}
				if *data2.State.Code != 48 {

					ec2data := EC2Data{
						InstanceId:   *data2.InstanceId,
						PrivateIP:    *data2.PrivateIpAddress,
						InstanceType: string(data2.InstanceType),
						Status:       string(data2.State.Name),
					}

					for _, tag := range data.Instances[0].Tags {
						tmp := strings.ReplaceAll(strings.ToLower(*tag.Key), " ", "")
						if tmp == "name" {
							ec2data.InstanceName = *tag.Value
						}

						if tmp == "usage" {
							ec2data.Usage = *tag.Value
						}

						if tmp == "hostname" {
							ec2data.Hostname = *tag.Value
						}

						if tmp == "osversion" {
							ec2data.OSVersion = *tag.Value
						}
						if tmp == "dbsafer" {
							ec2data.DBSafer = *tag.Value
						}
						if tmp == "riid" {
							for _, ridata := range ridatas {
								if strings.Contains(*tag.Value, ridata.RIID) {
									ec2data.RIData = append(ec2data.RIData, ridata)
								}
							}
						}
					}
					ec2datas = append(ec2datas, &ec2data)
				}
			}

		}
	}

	return ec2datas, ec2runningcount, ec2stoppedcount
}

func GetEC2RIData(cfg aws.Config) []*RIData {
	riclient := ec2.NewFromConfig(cfg)
	riinput := ec2.DescribeReservedInstancesInput{}
	rioutput, rioutputerr := riclient.DescribeReservedInstances(context.Background(), &riinput)
	check(rioutputerr)

	var ridatas []*RIData = make([]*RIData, 0)
	loc, err := time.LoadLocation("Asia/Seoul")
	if err != nil {
		panic(err)
	}

	for _, data := range rioutput.ReservedInstances {

		ridata := RIData{
			RIID:           *data.ReservedInstancesId,
			RIStart:        data.Start.In(loc),
			RIEnd:          data.End.In(loc),
			Platform:       string(data.ProductDescription),
			Tenancy:        string(data.InstanceTenancy),
			OfferingClass:  string(data.OfferingClass),
			OfferingType:   string(data.OfferingType),
			RIInstanceType: string(data.InstanceType),
			Term:           *data.Duration / 60 / 60 / 24,
			Count:          *data.InstanceCount,
		}
		ridatas = append(ridatas, &ridata)
	}
	return ridatas
}

func ReadClientKey() aws.Config {
	cfg, cfgerr := config.LoadDefaultConfig(
		context.Background(),
	)
	check(cfgerr)
	return cfg
}

func GetAccountId() string {
	cfg := ReadClientKey()

	client := sts.NewFromConfig(cfg)
	input := &sts.GetCallerIdentityInput{}

	req, err := client.GetCallerIdentity(context.TODO(), input)
	check(err)

	return *req.Account
}

func ReadAccount() []Account {
	cfg := ReadClientKey()
	s3client := s3.NewFromConfig(cfg)
	s3input := s3.GetObjectInput{
		Bucket:              aws.String(os.Getenv("bucketname")),
		Key:                 aws.String("client_list/client.csv"),
		ExpectedBucketOwner: aws.String(accountid),
	}
	s3output, outputerr := s3client.GetObject(context.TODO(), &s3input)
	if outputerr != nil {
		log.Fatalf("failed to get client_list/client.csv in bucket, %v", outputerr)
	}
	clientdatas, readcsverr := ReadCsv(s3output.Body)
	check(readcsverr)

	var accountlist []Account = make([]Account, 0)
	for i, data := range clientdatas {
		if i != 0 {
			accountdata := Account{
				AccountID:   data[0],
				AccountName: data[1],
				Filename:    data[2],
			}
			accountlist = append(accountlist, accountdata)
		}
	}
	return accountlist
}

func ReadCsv(f io.ReadCloser) ([][]string, error) {

	// Read File into a Variable
	lines, readcsverr := csv.NewReader(f).ReadAll()
	if readcsverr != nil {
		return [][]string{}, readcsverr
	}

	return lines, nil
}

func check(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

///////////////////////////////// Cloudfront ///////////////////////////////////////

func MakeCloudfrontValue(f *excelize.File, title string, rowindex int, accountName *string, result []*CFData, resource string) int { // 엑셀에 Cloudfront에 대한 실제 데이터 입력

	style := ValueStyle(f)

	for _, cfdata := range result {
		f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "G"+strconv.Itoa(rowindex), style)
		f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
		f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
		f.SetCellValue(title, "D"+strconv.Itoa(rowindex), cfdata.ID)
		f.SetCellValue(title, "E"+strconv.Itoa(rowindex), cfdata.DomainName)
		f.SetCellValue(title, "F"+strconv.Itoa(rowindex), cfdata.Enabled)
		f.SetCellValue(title, "G"+strconv.Itoa(rowindex), cfdata.OriginDomainName)
		rowindex = rowindex + 1
	}

	return rowindex
}

func MakeCloudfrontColumn(f *excelize.File, title string, rowindex int, resource string) int { // 엑셀에 Cloudfront의 실제 데이터에 대한 제목 입력

	style := ColumnStyle(f)

	f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "G"+strconv.Itoa(rowindex), style)
	f.SetCellValue(title, "B"+strconv.Itoa(rowindex), "Account")
	f.SetCellValue(title, "C"+strconv.Itoa(rowindex), "Service")
	f.SetCellValue(title, "D"+strconv.Itoa(rowindex), "CF ID")
	f.SetCellValue(title, "E"+strconv.Itoa(rowindex), "Domain Name")
	f.SetCellValue(title, "F"+strconv.Itoa(rowindex), "Enabled")
	f.SetCellValue(title, "G"+strconv.Itoa(rowindex), "Origin Domain Name")

	return rowindex + 1
}

func MakeCloudfrontSubtitle(f *excelize.File, title string, subtitle string, rowindex int) int { // 엑셀에 Cloudfront라는 소주제 입력
	err := f.MergeCell(title, "B"+strconv.Itoa(rowindex), "E"+strconv.Itoa(rowindex))
	if err != nil {
		log.Printf("Make SubTitle Error: %s", err.Error())
	}
	style, index := SubtitleStyle(f, rowindex)
	f.SetCellStyle(title, "B"+strconv.Itoa(index), "E"+strconv.Itoa(index), style)
	f.SetCellValue(title, "B"+strconv.Itoa(index), subtitle)
	return index + 2
}

///////////////////////////////////////Excelize RDS ////////////////////////////////////////////////////////////

func MakeRDSValue(f *excelize.File, title string, rowindex int, accountName *string, result []*RDSData, resource string) int { //액셀에 api로 가져온 정보를 넣는 함수
	for _, instance := range result { //가져온 모든 RDS 정보를 하나하나 제어할 수 있도록 반복문 생성
		style := ValueStyle(f) //엑셀의 실제 정보가 들어가는 셀에 어떤 스타일로 넣을지 정하는 함수

		f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "N"+strconv.Itoa(rowindex), style) //B열부터 N열까지 스타일 적용
		f.SetCellStyle(title, "O"+strconv.Itoa(rowindex), "Z"+strconv.Itoa(rowindex), style) //O열부터 Z열까지 스타일 적용

		if len(instance.RDSRIData) > 1 { //RDS 예약 노드가 1개 이상이라면 if 중괄호 부분을 실행
			for i := 0; i < 12; i++ { //해당 노드에 걸린 RI가 1개 이상이므로, 노드에 대한 정보는 중복이 되니, 중복되는 노드 정보는 셀 합치기로 설정
				err := f.MergeCell(title, string(toChar(i+2))+strconv.Itoa(rowindex), string(toChar(i+2))+strconv.Itoa(rowindex+len(instance.RDSRIData))) //toChar 함수 : 1 = A, 2 = B, 3 = C...로 바꿔주는 함수
				if err != nil {
					log.Printf("Make SubTitle Error: %s", err.Error())
				}
			}

			f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName) // rowindex : 셀이 위치하는 기준점 rowindex가 3일 때, B3열에 account명을 넣음
			f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
			f.SetCellValue(title, "D"+strconv.Itoa(rowindex), instance.Identifier)
			f.SetCellValue(title, "E"+strconv.Itoa(rowindex), instance.InstanceClass)
			f.SetCellValue(title, "F"+strconv.Itoa(rowindex), instance.Engine+" "+instance.EngineVersion)
			f.SetCellValue(title, "G"+strconv.Itoa(rowindex), instance.AllocatedStorage)
			f.SetCellValue(title, "H"+strconv.Itoa(rowindex), instance.StorageType)
			f.SetCellValue(title, "I"+strconv.Itoa(rowindex), instance.MultiAZ)
			f.SetCellValue(title, "J"+strconv.Itoa(rowindex), instance.Usage)
			f.SetCellValue(title, "K"+strconv.Itoa(rowindex), instance.DBSafer)
			f.SetCellValue(title, "L"+strconv.Itoa(rowindex), instance.CName)
			f.SetCellValue(title, "M"+strconv.Itoa(rowindex), instance.EndpointAddress)
			f.SetCellValue(title, "N"+strconv.Itoa(rowindex), instance.InstancePort)

			for i := 0; i < len(instance.RDSRIData); i++ { //해당 노드에 RI에 대한 정보가 있다면 값을 입력
				if instance.RDSRIData[i].EndTime.Before(time.Now().AddDate(0, 3, 0)) {
					colorstyle := ValueColorStyle(f)
					f.SetCellStyle(title, "O"+strconv.Itoa(rowindex), "Z"+strconv.Itoa(rowindex), colorstyle)
				}
				f.SetCellValue(title, "O"+strconv.Itoa(rowindex), instance.RDSRIData[0].LeaseId)
				f.SetCellValue(title, "P"+strconv.Itoa(rowindex), instance.RDSRIData[0].StartTime.Format("2006-01-02 15:04:05"))
				f.SetCellValue(title, "Q"+strconv.Itoa(rowindex), instance.RDSRIData[0].EndTime.Format("2006-01-02 15:04:05"))
				f.SetCellValue(title, "R"+strconv.Itoa(rowindex), instance.RDSRIData[0].DBInstanceClass)
				f.SetCellValue(title, "S"+strconv.Itoa(rowindex), instance.RDSRIData[0].DBInstanceCount)
				f.SetCellValue(title, "T"+strconv.Itoa(rowindex), instance.RDSRIData[0].Term)
				f.SetCellValue(title, "U"+strconv.Itoa(rowindex), instance.RDSRIData[0].MultiAZ)
				f.SetCellValue(title, "V"+strconv.Itoa(rowindex), instance.RDSRIData[0].OfferingType)
				f.SetCellValue(title, "W"+strconv.Itoa(rowindex), instance.RDSRIData[0].ProductDescription)
				f.SetCellValue(title, "X"+strconv.Itoa(rowindex), instance.RDSRIData[0].State)
				f.SetCellValue(title, "Y"+strconv.Itoa(rowindex), instance.RDSRIData[0].ReservedDBInstanceId)
				f.SetCellValue(title, "Z"+strconv.Itoa(rowindex), instance.RDSRIData[0].ReservedDBInstancesOfferingId)

				rowindex++
			}
		} else if instance.RDSRIData == nil { //RI에 대한 정보가 없을 경우 노드 정보만 출력
			f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
			f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
			f.SetCellValue(title, "D"+strconv.Itoa(rowindex), instance.Identifier)
			f.SetCellValue(title, "E"+strconv.Itoa(rowindex), instance.InstanceClass)
			f.SetCellValue(title, "F"+strconv.Itoa(rowindex), instance.Engine+" "+instance.EngineVersion)
			f.SetCellValue(title, "G"+strconv.Itoa(rowindex), instance.AllocatedStorage)
			f.SetCellValue(title, "H"+strconv.Itoa(rowindex), instance.StorageType)
			f.SetCellValue(title, "I"+strconv.Itoa(rowindex), instance.MultiAZ)
			f.SetCellValue(title, "J"+strconv.Itoa(rowindex), instance.Usage)
			f.SetCellValue(title, "K"+strconv.Itoa(rowindex), instance.DBSafer)
			f.SetCellValue(title, "L"+strconv.Itoa(rowindex), instance.CName)
			f.SetCellValue(title, "M"+strconv.Itoa(rowindex), instance.EndpointAddress)
			f.SetCellValue(title, "N"+strconv.Itoa(rowindex), instance.InstancePort)
			rowindex++
		} else { // RI가 1개만 할당 되어있을 경우 해당 노드와 연결된 RI 정보를 출력
			f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
			f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
			f.SetCellValue(title, "D"+strconv.Itoa(rowindex), instance.Identifier)
			f.SetCellValue(title, "E"+strconv.Itoa(rowindex), instance.InstanceClass)
			f.SetCellValue(title, "F"+strconv.Itoa(rowindex), instance.Engine+" "+instance.EngineVersion)
			f.SetCellValue(title, "G"+strconv.Itoa(rowindex), instance.AllocatedStorage)
			f.SetCellValue(title, "H"+strconv.Itoa(rowindex), instance.StorageType)
			f.SetCellValue(title, "I"+strconv.Itoa(rowindex), instance.MultiAZ)
			f.SetCellValue(title, "J"+strconv.Itoa(rowindex), instance.Usage)
			f.SetCellValue(title, "K"+strconv.Itoa(rowindex), instance.DBSafer)
			f.SetCellValue(title, "L"+strconv.Itoa(rowindex), instance.CName)
			f.SetCellValue(title, "M"+strconv.Itoa(rowindex), instance.EndpointAddress)
			f.SetCellValue(title, "N"+strconv.Itoa(rowindex), instance.InstancePort)

			f.SetCellValue(title, "O"+strconv.Itoa(rowindex), instance.RDSRIData[0].LeaseId)
			f.SetCellValue(title, "P"+strconv.Itoa(rowindex), instance.RDSRIData[0].StartTime.Format("2006-01-02 15:04:05"))
			f.SetCellValue(title, "Q"+strconv.Itoa(rowindex), instance.RDSRIData[0].EndTime.Format("2006-01-02 15:04:05"))
			f.SetCellValue(title, "R"+strconv.Itoa(rowindex), instance.RDSRIData[0].DBInstanceClass)
			f.SetCellValue(title, "S"+strconv.Itoa(rowindex), instance.RDSRIData[0].DBInstanceCount)
			f.SetCellValue(title, "T"+strconv.Itoa(rowindex), instance.RDSRIData[0].Term)
			f.SetCellValue(title, "U"+strconv.Itoa(rowindex), instance.RDSRIData[0].MultiAZ)
			f.SetCellValue(title, "V"+strconv.Itoa(rowindex), instance.RDSRIData[0].OfferingType)
			f.SetCellValue(title, "W"+strconv.Itoa(rowindex), instance.RDSRIData[0].ProductDescription)
			f.SetCellValue(title, "X"+strconv.Itoa(rowindex), instance.RDSRIData[0].State)
			f.SetCellValue(title, "Y"+strconv.Itoa(rowindex), instance.RDSRIData[0].ReservedDBInstanceId)
			f.SetCellValue(title, "Z"+strconv.Itoa(rowindex), instance.RDSRIData[0].ReservedDBInstancesOfferingId)
			rowindex++
		}

	}

	return rowindex
}

func MakeRDSColumn(f *excelize.File, title string, rowindex int, resource string) int { // 엑셀에서 RDS에 출력될 각 정보의 제목을 엑셀에 입력
	style := ColumnStyle(f) // 제목에 설정할 스타일을 결정하는 함수

	f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "Z"+strconv.Itoa(rowindex), style) // 스타일을 B열부터 Z열까지 기준점에 해당되는 행에 적용
	f.SetCellValue(title, "B"+strconv.Itoa(rowindex), "Account")
	f.SetCellValue(title, "C"+strconv.Itoa(rowindex), "Services")
	f.SetCellValue(title, "D"+strconv.Itoa(rowindex), "DB Identifier")
	f.SetCellValue(title, "E"+strconv.Itoa(rowindex), "Instance Class")
	f.SetCellValue(title, "F"+strconv.Itoa(rowindex), "Engine")
	f.SetCellValue(title, "G"+strconv.Itoa(rowindex), "Allocated Storage")
	f.SetCellValue(title, "H"+strconv.Itoa(rowindex), "Storage Type")
	f.SetCellValue(title, "I"+strconv.Itoa(rowindex), "MultiAZ")
	f.SetCellValue(title, "J"+strconv.Itoa(rowindex), "Usage")
	f.SetCellValue(title, "K"+strconv.Itoa(rowindex), "DB Safer")
	f.SetCellValue(title, "L"+strconv.Itoa(rowindex), "CName")
	f.SetCellValue(title, "M"+strconv.Itoa(rowindex), "Endpoint")
	f.SetCellValue(title, "N"+strconv.Itoa(rowindex), "Port")

	f.SetCellValue(title, "O"+strconv.Itoa(rowindex), "Lease ID")
	f.SetCellValue(title, "P"+strconv.Itoa(rowindex), "Start")
	f.SetCellValue(title, "Q"+strconv.Itoa(rowindex), "End")
	f.SetCellValue(title, "R"+strconv.Itoa(rowindex), "DB RI Instance Class")
	f.SetCellValue(title, "S"+strconv.Itoa(rowindex), "DB RI Instance Count")
	f.SetCellValue(title, "T"+strconv.Itoa(rowindex), "Term")
	f.SetCellValue(title, "U"+strconv.Itoa(rowindex), "MultiAZ")
	f.SetCellValue(title, "V"+strconv.Itoa(rowindex), "Offering Type")
	f.SetCellValue(title, "W"+strconv.Itoa(rowindex), "Product Description")
	f.SetCellValue(title, "X"+strconv.Itoa(rowindex), "State")
	f.SetCellValue(title, "Y"+strconv.Itoa(rowindex), "Reserved DB Instance Id")
	f.SetCellValue(title, "Z"+strconv.Itoa(rowindex), "Reserved DB Instances Offering Id")

	return rowindex + 1
}

func MakeRDSSubtitle(f *excelize.File, title string, subtitle string, rowindex int) int { // 엑셀에 RDS 라는 소제목을 입력하는 함수
	rowindex = rowindex + 2
	err := f.MergeCell(title, "B"+strconv.Itoa(rowindex), "D"+strconv.Itoa(rowindex))
	if err != nil {
		log.Printf("Make SubTitle Error: %s", err.Error())
	}
	style, index := SubtitleStyle(f, rowindex)
	f.SetCellStyle(title, "B"+strconv.Itoa(index), "D"+strconv.Itoa(index), style)
	f.SetCellValue(title, "B"+strconv.Itoa(index), subtitle)
	return index + 2
}

// //////////////////////////// Cluster ///////////////////////////

func MakeClusterRDSColumn(f *excelize.File, title string, rowindex int, resource string) int { // 엑셀에 Cluster에 속한 노드의 실제 데이터에 대한 소제목 입력
	style := ColumnStyle(f)

	f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "W"+strconv.Itoa(rowindex), style)
	f.SetCellValue(title, "B"+strconv.Itoa(rowindex), "Account")
	f.SetCellValue(title, "C"+strconv.Itoa(rowindex), "Services")
	f.SetCellValue(title, "D"+strconv.Itoa(rowindex), "Cluster Identifier")
	f.SetCellValue(title, "E"+strconv.Itoa(rowindex), "DB Identifier")
	f.SetCellValue(title, "F"+strconv.Itoa(rowindex), "Instance Class")
	f.SetCellValue(title, "G"+strconv.Itoa(rowindex), "Engine")
	f.SetCellValue(title, "H"+strconv.Itoa(rowindex), "Allocated Storage")
	f.SetCellValue(title, "I"+strconv.Itoa(rowindex), "Storage Type")
	f.SetCellValue(title, "J"+strconv.Itoa(rowindex), "MultiAZ")
	f.SetCellValue(title, "K"+strconv.Itoa(rowindex), "Usage")

	f.SetCellValue(title, "L"+strconv.Itoa(rowindex), "Lease ID")
	f.SetCellValue(title, "M"+strconv.Itoa(rowindex), "Start")
	f.SetCellValue(title, "N"+strconv.Itoa(rowindex), "End")
	f.SetCellValue(title, "O"+strconv.Itoa(rowindex), "DB RI Instance Class")
	f.SetCellValue(title, "P"+strconv.Itoa(rowindex), "DB RI Instance Count")
	f.SetCellValue(title, "Q"+strconv.Itoa(rowindex), "Term")
	f.SetCellValue(title, "R"+strconv.Itoa(rowindex), "MultiAZ")
	f.SetCellValue(title, "S"+strconv.Itoa(rowindex), "Offering Type")
	f.SetCellValue(title, "T"+strconv.Itoa(rowindex), "Product Description")
	f.SetCellValue(title, "U"+strconv.Itoa(rowindex), "State")
	f.SetCellValue(title, "V"+strconv.Itoa(rowindex), "Reserved DB Instance Id")
	f.SetCellValue(title, "W"+strconv.Itoa(rowindex), "Reserved DB Instances Offering Id")
	return rowindex + 1
}

func MakeClusterValue(f *excelize.File, title string, rowindex int, accountName *string, result []*ClusterData, resource string) int { // 엑셀에 Cluster 실제 데이터 입력
	for _, cluster := range result {
		rowindex = MakeClusterColumn(f, title, rowindex, "rds")
		style := ValueStyle(f)
		f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "P"+strconv.Itoa(rowindex), style)
		f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
		f.SetCellValue(title, "C"+strconv.Itoa(rowindex), "Cluster")
		f.SetCellValue(title, "D"+strconv.Itoa(rowindex), cluster.Identifier)

		f.SetCellValue(title, "F"+strconv.Itoa(rowindex), cluster.Engine+" "+cluster.EngineVersion)
		f.SetCellValue(title, "G"+strconv.Itoa(rowindex), cluster.Port)
		f.SetCellValue(title, "H"+strconv.Itoa(rowindex), cluster.MultiAZ)
		f.SetCellValue(title, "J"+strconv.Itoa(rowindex), cluster.Status)
		f.SetCellValue(title, "K"+strconv.Itoa(rowindex), cluster.Usage)
		f.SetCellValue(title, "L"+strconv.Itoa(rowindex), cluster.DBSafer)
		f.SetCellValue(title, "M"+strconv.Itoa(rowindex), cluster.CName)
		f.SetCellValue(title, "N"+strconv.Itoa(rowindex), cluster.EndPoint)
		f.SetCellValue(title, "O"+strconv.Itoa(rowindex), cluster.ReaderEndpoint)
		f.SetCellValue(title, "P"+strconv.Itoa(rowindex), cluster.Port)
		rowindex++
		if cluster.RDSData != nil { // RI 정보가 있을 경우

			rowindex = MakeClusterRDSColumn(f, title, rowindex, "rds")
			for _, instance := range cluster.RDSData {
				style := ValueStyle(f)
				f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "W"+strconv.Itoa(rowindex), style)
				f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
				f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
				f.SetCellValue(title, "E"+strconv.Itoa(rowindex), instance.Identifier)
				f.SetCellValue(title, "F"+strconv.Itoa(rowindex), instance.InstanceClass)
				f.SetCellValue(title, "G"+strconv.Itoa(rowindex), instance.Engine+" "+instance.EngineVersion)
				f.SetCellValue(title, "H"+strconv.Itoa(rowindex), instance.AllocatedStorage)
				f.SetCellValue(title, "I"+strconv.Itoa(rowindex), instance.StorageType)
				f.SetCellValue(title, "J"+strconv.Itoa(rowindex), instance.MultiAZ)
				f.SetCellValue(title, "K"+strconv.Itoa(rowindex), instance.Usage)
				if instance.RDSRIData != nil {
					f.SetCellValue(title, "L"+strconv.Itoa(rowindex), instance.RDSRIData[0].LeaseId)
					f.SetCellValue(title, "M"+strconv.Itoa(rowindex), instance.RDSRIData[0].StartTime.Format("2006-01-02 15:04:05"))
					f.SetCellValue(title, "N"+strconv.Itoa(rowindex), instance.RDSRIData[0].EndTime.Format("2006-01-02 15:04:05"))
					f.SetCellValue(title, "O"+strconv.Itoa(rowindex), instance.RDSRIData[0].DBInstanceClass)
					f.SetCellValue(title, "P"+strconv.Itoa(rowindex), instance.RDSRIData[0].DBInstanceCount)
					f.SetCellValue(title, "Q"+strconv.Itoa(rowindex), instance.RDSRIData[0].Term)
					f.SetCellValue(title, "R"+strconv.Itoa(rowindex), instance.RDSRIData[0].MultiAZ)
					f.SetCellValue(title, "S"+strconv.Itoa(rowindex), instance.RDSRIData[0].OfferingType)
					f.SetCellValue(title, "T"+strconv.Itoa(rowindex), instance.RDSRIData[0].ProductDescription)
					f.SetCellValue(title, "U"+strconv.Itoa(rowindex), instance.RDSRIData[0].State)
					f.SetCellValue(title, "V"+strconv.Itoa(rowindex), instance.RDSRIData[0].ReservedDBInstanceId)
					f.SetCellValue(title, "W"+strconv.Itoa(rowindex), instance.RDSRIData[0].ReservedDBInstancesOfferingId)
				}
				rowindex++
			}
		}

	}

	return rowindex
}

func MakeClusterColumn(f *excelize.File, title string, rowindex int, resource string) int { // 엑셀에 Cluster 실제 데이터에 대한 소제목 입력

	style := ColumnStyle(f)

	f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "P"+strconv.Itoa(rowindex), style)
	f.SetCellValue(title, "B"+strconv.Itoa(rowindex), "Account")
	f.SetCellValue(title, "C"+strconv.Itoa(rowindex), "Service")
	f.SetCellValue(title, "D"+strconv.Itoa(rowindex), "Cluster ID")
	f.SetCellValue(title, "E"+strconv.Itoa(rowindex), "Cluster Class")
	f.SetCellValue(title, "F"+strconv.Itoa(rowindex), "Cluster Engine")
	f.SetCellValue(title, "G"+strconv.Itoa(rowindex), "Cluster Port")
	f.SetCellValue(title, "H"+strconv.Itoa(rowindex), "Cluster MultiAZ")
	f.SetCellValue(title, "I"+strconv.Itoa(rowindex), "Cluster Status")
	f.SetCellValue(title, "J"+strconv.Itoa(rowindex), "Cluster Storage Type")
	f.SetCellValue(title, "K"+strconv.Itoa(rowindex), "Cluster Usage")
	f.SetCellValue(title, "L"+strconv.Itoa(rowindex), "DB Safer")
	f.SetCellValue(title, "M"+strconv.Itoa(rowindex), "CName")
	f.SetCellValue(title, "N"+strconv.Itoa(rowindex), "Endpoint")
	f.SetCellValue(title, "O"+strconv.Itoa(rowindex), "Reader Endpoint")
	f.SetCellValue(title, "P"+strconv.Itoa(rowindex), "Port")

	return rowindex + 1
}

func MakeClusterSubtitle(f *excelize.File, title string, subtitle string, rowindex int) int { // 엑셀에 Cluster라는 주제 입력
	err := f.MergeCell(title, "B"+strconv.Itoa(rowindex), "D"+strconv.Itoa(rowindex))
	if err != nil {
		log.Printf("Make SubTitle Error: %s", err.Error())
	}
	style, index := SubtitleStyle(f, rowindex)
	f.SetCellStyle(title, "B"+strconv.Itoa(index), "D"+strconv.Itoa(index), style)
	f.SetCellValue(title, "B"+strconv.Itoa(index), subtitle)
	return index + 2
}

///////////////////////////////// Cloudwatch ///////////////////////////////////////

func MakeCloudwatchAlarmValue(f *excelize.File, title string, rowindex int, accountName *string, result []*AlarmData, resource string) int { // 엑셀에 Cloudwatch Alarm에 대한 실제 데이터 입력

	style := ValueStyle(f)

	for _, alarmdata := range result {
		f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "O"+strconv.Itoa(rowindex), style)
		f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
		f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
		f.SetCellValue(title, "D"+strconv.Itoa(rowindex), alarmdata.Name)
		f.SetCellValue(title, "E"+strconv.Itoa(rowindex), alarmdata.Eabled)
		f.SetCellValue(title, "F"+strconv.Itoa(rowindex), alarmdata.Actions)
		f.SetCellValue(title, "G"+strconv.Itoa(rowindex), alarmdata.ComparisonOperator)
		f.SetCellValue(title, "H"+strconv.Itoa(rowindex), alarmdata.DatapointsToAlarm)
		f.SetCellValue(title, "I"+strconv.Itoa(rowindex), alarmdata.DimensionName)
		f.SetCellValue(title, "J"+strconv.Itoa(rowindex), alarmdata.DimensionValue)
		f.SetCellValue(title, "K"+strconv.Itoa(rowindex), alarmdata.EvaluationPeriods)
		f.SetCellValue(title, "L"+strconv.Itoa(rowindex), alarmdata.Period)
		f.SetCellValue(title, "M"+strconv.Itoa(rowindex), alarmdata.Statistic)
		f.SetCellValue(title, "N"+strconv.Itoa(rowindex), alarmdata.Threshold)
		f.SetCellValue(title, "O"+strconv.Itoa(rowindex), alarmdata.TreatMissingData)
		rowindex = rowindex + 1
	}

	return rowindex
}

func MakeCloudwatchAlarmColumn(f *excelize.File, title string, rowindex int, resource string) int { // 엑셀에 Cloudwatch Alarm의 실제 데이터에 대한 제목 입력

	style := ColumnStyle(f)

	f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "O"+strconv.Itoa(rowindex), style)
	f.SetCellValue(title, "B"+strconv.Itoa(rowindex), "Account")
	f.SetCellValue(title, "C"+strconv.Itoa(rowindex), "Service")
	f.SetCellValue(title, "D"+strconv.Itoa(rowindex), "Alarm Name")
	f.SetCellValue(title, "E"+strconv.Itoa(rowindex), "Enabled")
	f.SetCellValue(title, "F"+strconv.Itoa(rowindex), "Actions")
	f.SetCellValue(title, "G"+strconv.Itoa(rowindex), "Comparison Operator")
	f.SetCellValue(title, "H"+strconv.Itoa(rowindex), "Datapoints To Alarm")
	f.SetCellValue(title, "I"+strconv.Itoa(rowindex), "Dimension Name")
	f.SetCellValue(title, "J"+strconv.Itoa(rowindex), "Dimension Value")
	f.SetCellValue(title, "K"+strconv.Itoa(rowindex), "Evaluation Periods")
	f.SetCellValue(title, "L"+strconv.Itoa(rowindex), "Period")
	f.SetCellValue(title, "M"+strconv.Itoa(rowindex), "Statistic")
	f.SetCellValue(title, "N"+strconv.Itoa(rowindex), "Threshold")
	f.SetCellValue(title, "O"+strconv.Itoa(rowindex), "Treat Missing Data")

	return rowindex + 1
}

func MakeCloudwatchAlarmSubtitle(f *excelize.File, title string, subtitle string, rowindex int) int { // 엑셀에 Cloudwatch Alarm이라는 소주제 입력
	err := f.MergeCell(title, "B"+strconv.Itoa(rowindex), "E"+strconv.Itoa(rowindex))
	if err != nil {
		log.Printf("Make SubTitle Error: %s", err.Error())
	}
	style, index := SubtitleStyle(f, rowindex)
	f.SetCellStyle(title, "B"+strconv.Itoa(index), "E"+strconv.Itoa(index), style)
	f.SetCellValue(title, "B"+strconv.Itoa(index), subtitle)
	return index + 2
}

//////////////////////////////// VPC //////////////////////////////////////////

func MakeVPCValue(f *excelize.File, title string, rowindex int, accountName *string, result []*VPCData, resource string) int { // 엑셀에 VPC에 대한 실제 데이터 입력
	for _, vpcdata := range result {

		style := ValueStyle(f)

		f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "F"+strconv.Itoa(rowindex), style)
		f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
		f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
		f.SetCellValue(title, "D"+strconv.Itoa(rowindex), vpcdata.Id)
		f.SetCellValue(title, "E"+strconv.Itoa(rowindex), vpcdata.Name)
		f.SetCellValue(title, "F"+strconv.Itoa(rowindex), vpcdata.Cidr)

		rowindex++
	}

	return rowindex
}

func MakeVPCColumn(f *excelize.File, title string, rowindex int, resource string) int { // 엑셀에 VPC 실제 데이터에 대한 소제목 입력

	style := ColumnStyle(f)

	f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "F"+strconv.Itoa(rowindex), style)
	f.SetCellValue(title, "B"+strconv.Itoa(rowindex), "Account")
	f.SetCellValue(title, "C"+strconv.Itoa(rowindex), "Service")
	f.SetCellValue(title, "D"+strconv.Itoa(rowindex), "ID")
	f.SetCellValue(title, "E"+strconv.Itoa(rowindex), "Name")
	f.SetCellValue(title, "F"+strconv.Itoa(rowindex), "Cidr Block")

	return rowindex + 1
}

func MakeVPCSubtitle(f *excelize.File, title string, subtitle string, rowindex int) int { //엑셀에 VPC라는 소주제 입력
	err := f.MergeCell(title, "B"+strconv.Itoa(rowindex), "D"+strconv.Itoa(rowindex))
	if err != nil {
		log.Printf("Make SubTitle Error: %s", err.Error())
	}
	style, index := SubtitleStyle(f, rowindex)
	f.SetCellStyle(title, "B"+strconv.Itoa(index), "D"+strconv.Itoa(index), style)
	f.SetCellValue(title, "B"+strconv.Itoa(index), subtitle)
	return index + 2
}

//////////////////////////////// Subnet //////////////////////////////////////////

func MakeSubnetValue(f *excelize.File, title string, rowindex int, accountName *string, result []*SubnetData, resource string) int { // 엑셀에 서브넷에 대한 실제 데이터 입력
	for _, subnetdata := range result {

		style := ValueStyle(f)

		f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "G"+strconv.Itoa(rowindex), style)
		f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
		f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
		f.SetCellValue(title, "D"+strconv.Itoa(rowindex), subnetdata.VPCId)
		f.SetCellValue(title, "E"+strconv.Itoa(rowindex), subnetdata.SubnetId)
		f.SetCellValue(title, "F"+strconv.Itoa(rowindex), subnetdata.Name)
		f.SetCellValue(title, "G"+strconv.Itoa(rowindex), subnetdata.Cidr)

		rowindex++
	}

	return rowindex
}

func MakeSubnetColumn(f *excelize.File, title string, rowindex int, resource string) int { // 엑셀에 서브넷 실제 데이터에 대한 제목 입력

	style := ColumnStyle(f)

	f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "G"+strconv.Itoa(rowindex), style)
	f.SetCellValue(title, "B"+strconv.Itoa(rowindex), "Account")
	f.SetCellValue(title, "C"+strconv.Itoa(rowindex), "Service")
	f.SetCellValue(title, "D"+strconv.Itoa(rowindex), "VPC ID")
	f.SetCellValue(title, "E"+strconv.Itoa(rowindex), "Subnet ID")
	f.SetCellValue(title, "F"+strconv.Itoa(rowindex), "Name")
	f.SetCellValue(title, "G"+strconv.Itoa(rowindex), "Cidr")

	return rowindex + 1
}

func MakeSubnetSubtitle(f *excelize.File, title string, subtitle string, rowindex int) int { // 엑셀에 서브넷 이라는 소주제 입력
	err := f.MergeCell(title, "B"+strconv.Itoa(rowindex), "D"+strconv.Itoa(rowindex))
	if err != nil {
		log.Printf("Make SubTitle Error: %s", err.Error())
	}
	style, index := SubtitleStyle(f, rowindex)
	f.SetCellStyle(title, "B"+strconv.Itoa(index), "D"+strconv.Itoa(index), style)
	f.SetCellValue(title, "B"+strconv.Itoa(index), subtitle)
	return index + 2
}

//////////////////////////////// VPN //////////////////////////////////////////

func MakeVPNValue(f *excelize.File, title string, rowindex int, accountName *string, result []*VPNData, resource string) int { // 엑셀에 VPN 실제 데이터 입력
	for _, vpndata := range result {

		style := ValueStyle(f)

		f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "D"+strconv.Itoa(rowindex), style)
		f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
		f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
		f.SetCellValue(title, "D"+strconv.Itoa(rowindex), vpndata.Name)

		rowindex++
	}

	return rowindex
}

func MakeVPNColumn(f *excelize.File, title string, rowindex int, resource string) int { // 엑셀에 VPN 실제 데이터에 대한 제목 입력

	style := ColumnStyle(f)

	f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "D"+strconv.Itoa(rowindex), style)
	f.SetCellValue(title, "B"+strconv.Itoa(rowindex), "Account")
	f.SetCellValue(title, "C"+strconv.Itoa(rowindex), "Service")
	f.SetCellValue(title, "D"+strconv.Itoa(rowindex), "Name")

	return rowindex + 1
}

func MakeVPNSubtitle(f *excelize.File, title string, subtitle string, rowindex int) int { // 엑셀에 VPN이라는 소주제 입력
	err := f.MergeCell(title, "B"+strconv.Itoa(rowindex), "D"+strconv.Itoa(rowindex))
	if err != nil {
		log.Printf("Make SubTitle Error: %s", err.Error())
	}
	style, index := SubtitleStyle(f, rowindex)
	f.SetCellStyle(title, "B"+strconv.Itoa(index), "D"+strconv.Itoa(index), style)
	f.SetCellValue(title, "B"+strconv.Itoa(index), subtitle)
	return index + 2
}

func MakeSGValue(f *excelize.File, title string, rowindex int, accountName *string, result []*SecurityGroupRuleData, resource string) int { // 엑셀에 보안그룹에 대한 실제 데이터 입력
	for _, sgdata := range result {

		style := ValueStyle(f)

		f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "K"+strconv.Itoa(rowindex), style)
		f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
		f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
		f.SetCellValue(title, "D"+strconv.Itoa(rowindex), sgdata.GroupName)
		f.SetCellValue(title, "E"+strconv.Itoa(rowindex), sgdata.GroupID)
		f.SetCellValue(title, "F"+strconv.Itoa(rowindex), sgdata.RuleID)
		f.SetCellValue(title, "G"+strconv.Itoa(rowindex), sgdata.InOutbound)
		f.SetCellValue(title, "H"+strconv.Itoa(rowindex), sgdata.SrcAddr)
		f.SetCellValue(title, "I"+strconv.Itoa(rowindex), sgdata.Protocol)
		f.SetCellValue(title, "J"+strconv.Itoa(rowindex), sgdata.Port)
		f.SetCellValue(title, "K"+strconv.Itoa(rowindex), sgdata.Description)
		rowindex++
	}

	return rowindex
}

func MakeSGColumn(f *excelize.File, title string, rowindex int, resource string) int { // 엑셀에 보안그룹 실제 데이터에 대한 제목 입력

	style := ColumnStyle(f)

	f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "K"+strconv.Itoa(rowindex), style)
	f.SetCellValue(title, "B"+strconv.Itoa(rowindex), "Account")
	f.SetCellValue(title, "C"+strconv.Itoa(rowindex), "Service")
	f.SetCellValue(title, "D"+strconv.Itoa(rowindex), "Group Name")
	f.SetCellValue(title, "E"+strconv.Itoa(rowindex), "Group ID")
	f.SetCellValue(title, "F"+strconv.Itoa(rowindex), "Rule ID")
	f.SetCellValue(title, "G"+strconv.Itoa(rowindex), "In/Outbound")
	f.SetCellValue(title, "H"+strconv.Itoa(rowindex), "Source")
	f.SetCellValue(title, "I"+strconv.Itoa(rowindex), "Protocol")
	f.SetCellValue(title, "J"+strconv.Itoa(rowindex), "Port")
	f.SetCellValue(title, "K"+strconv.Itoa(rowindex), "Description")

	return rowindex + 1
}

func MakeSGSubtitle(f *excelize.File, title string, subtitle string, rowindex int) int { // 엑셀에 보안그룹이라는 소주제 입력
	err := f.MergeCell(title, "B"+strconv.Itoa(rowindex), "D"+strconv.Itoa(rowindex))
	if err != nil {
		log.Printf("Make SubTitle Error: %s", err.Error())
	}
	style, index := SubtitleStyle(f, rowindex)
	f.SetCellStyle(title, "B"+strconv.Itoa(index), "D"+strconv.Itoa(index), style)
	f.SetCellValue(title, "B"+strconv.Itoa(index), subtitle)
	return index + 2
}

/////////////////////////////////S3///////////////////////////////////////

func MakeS3Value(f *excelize.File, title string, rowindex int, accountName *string, result []*S3Data, resource string) int { // 엑셀에 S3에 대한 실제 데이터 입력
	for _, s3data := range result {

		style := ValueStyle(f)

		f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "E"+strconv.Itoa(rowindex), style)
		f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
		f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
		f.SetCellValue(title, "D"+strconv.Itoa(rowindex), s3data.Name)
		f.SetCellValue(title, "E"+strconv.Itoa(rowindex), s3data.CreatedDate)
		rowindex++
	}

	return rowindex
}

func MakeS3Column(f *excelize.File, title string, rowindex int, resource string) int { // 엑셀에 S3 실제 데이터에 대한 제목 입력

	style := ColumnStyle(f)

	f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "E"+strconv.Itoa(rowindex), style)
	f.SetCellValue(title, "B"+strconv.Itoa(rowindex), "Account")
	f.SetCellValue(title, "C"+strconv.Itoa(rowindex), "Service")
	f.SetCellValue(title, "D"+strconv.Itoa(rowindex), "Bucket Name")
	f.SetCellValue(title, "E"+strconv.Itoa(rowindex), "Created Date")

	return rowindex + 1
}

func MakeS3Subtitle(f *excelize.File, title string, subtitle string, rowindex int) int { // 엑셀에 S3라는 소주제 입력
	err := f.MergeCell(title, "B"+strconv.Itoa(rowindex), "E"+strconv.Itoa(rowindex))
	if err != nil {
		log.Printf("Make SubTitle Error: %s", err.Error())
	}
	style, index := SubtitleStyle(f, rowindex)
	f.SetCellStyle(title, "B"+strconv.Itoa(index), "E"+strconv.Itoa(index), style)
	f.SetCellValue(title, "B"+strconv.Itoa(index), subtitle)
	return index + 2
}

/////////////////////////////////NGW///////////////////////////////////////

func MakeNatGatewayValue(f *excelize.File, title string, rowindex int, accountName *string, result []*NatGatewayData, resource string) int { // 엑셀에 NAT Gateway 실제 데이터 입력
	for _, ngwdata := range result {

		style := ValueStyle(f)

		f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "D"+strconv.Itoa(rowindex), style)
		f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
		f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
		f.SetCellValue(title, "D"+strconv.Itoa(rowindex), ngwdata.Name)
		rowindex++
	}

	return rowindex
}

func MakeNatGatewayColumn(f *excelize.File, title string, rowindex int, resource string) int { // 엑셀에 NAT Gateway 실제 데이터에 대한 제목 입력

	style := ColumnStyle(f)

	f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "D"+strconv.Itoa(rowindex), style)
	f.SetCellValue(title, "B"+strconv.Itoa(rowindex), "Account")
	f.SetCellValue(title, "C"+strconv.Itoa(rowindex), "Service")
	f.SetCellValue(title, "D"+strconv.Itoa(rowindex), "Nat Gateway Name")

	return rowindex + 1
}

func MakeNatGatewaySubtitle(f *excelize.File, title string, subtitle string, rowindex int) int { // 엑셀에 NAT Gateway라는 소주제 입력
	err := f.MergeCell(title, "B"+strconv.Itoa(rowindex), "D"+strconv.Itoa(rowindex))
	if err != nil {
		log.Printf("Make SubTitle Error: %s", err.Error())
	}
	style, index := SubtitleStyle(f, rowindex)
	f.SetCellStyle(title, "B"+strconv.Itoa(index), "D"+strconv.Itoa(index), style)
	f.SetCellValue(title, "B"+strconv.Itoa(index), subtitle)
	return index + 2
}

func MakeTargetGroupValue(f *excelize.File, title string, rowindex int, accountName *string, result []*TargetGroupData, resource string) int { // 엑셀에 타겟 그룹에 대한 실제 데이터 입력
	for _, tgdata := range result {
		/* // 타겟그룹과 연결된 리스너 규칙을 불러오는
		for i := 0; i < 6; i++ {
			err := f.MergeCell(title, string(toChar(i+2))+strconv.Itoa(rowindex), string(toChar(i+2))+strconv.Itoa(rowindex+len(tgdata.ListenerRules)))
			if err != nil {
				log.Printf("Make SubTitle Error: %s", err.Error())
			}
		}

		for i := 9; i < 16; i++ {
			err := f.MergeCell(title, string(toChar(i+2))+strconv.Itoa(rowindex), string(toChar(i+2))+strconv.Itoa(rowindex+len(tgdata.ListenerRules)))
			if err != nil {
				log.Printf("Make SubTitle Error: %s", err.Error())
			}
		}
		*/
		style := ValueStyle(f)
		f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "H"+strconv.Itoa(rowindex), style)
		f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
		f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
		f.SetCellValue(title, "D"+strconv.Itoa(rowindex), tgdata.Name)
		f.SetCellValue(title, "E"+strconv.Itoa(rowindex), tgdata.Protocol)
		f.SetCellValue(title, "F"+strconv.Itoa(rowindex), tgdata.Port)
		f.SetCellValue(title, "G"+strconv.Itoa(rowindex), tgdata.LBARN)
		f.SetCellValue(title, "H"+strconv.Itoa(rowindex), tgdata.TargetARN)
		rowindex++
		/*
			if strings.ToLower(os.Getenv("GetListenerRuleData")) == "yes" && tgdata.ListenerRules != nil {

				f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
				f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
				f.SetCellValue(title, "D"+strconv.Itoa(rowindex), tgdata.Name)
				f.SetCellValue(title, "E"+strconv.Itoa(rowindex), tgdata.Protocol)
				f.SetCellValue(title, "F"+strconv.Itoa(rowindex), tgdata.Port)
				f.SetCellValue(title, "G"+strconv.Itoa(rowindex), tgdata.TargetARN)

				f.SetCellValue(title, "K"+strconv.Itoa(rowindex), tgdata.TargetIDs)
				f.SetCellValue(title, "L"+strconv.Itoa(rowindex), tgdata.HealthCheckProtocol)
				f.SetCellValue(title, "M"+strconv.Itoa(rowindex), tgdata.HealthCheckPort)
				f.SetCellValue(title, "N"+strconv.Itoa(rowindex), tgdata.HealthCheckPath)
				f.SetCellValue(title, "O"+strconv.Itoa(rowindex), tgdata.HealthCheckTimeoutSeconds)
				f.SetCellValue(title, "P"+strconv.Itoa(rowindex), tgdata.HealthCheckThresholdCount)
				f.SetCellValue(title, "Q"+strconv.Itoa(rowindex), tgdata.UnhealthyThresholdCount)

				for _, listenerrule := range tgdata.ListenerRules {
					var tmpcondition string = ""
					for i, condition := range listenerrule.Condition {
						tmpcondition += condition.Field + ": " + condition.Value
						if i < len(listenerrule.Condition) {
							tmpcondition += ", "
						}
					}
					f.SetCellValue(title, "H"+strconv.Itoa(rowindex), listenerrule.ListenerARN)
					f.SetCellValue(title, "I"+strconv.Itoa(rowindex), tmpcondition)
					f.SetCellValue(title, "J"+strconv.Itoa(rowindex), listenerrule.StickyEnabled)
					rowindex++
				}
			} else {
				f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
				f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
				f.SetCellValue(title, "D"+strconv.Itoa(rowindex), tgdata.Name)
				f.SetCellValue(title, "E"+strconv.Itoa(rowindex), tgdata.Protocol)
				f.SetCellValue(title, "F"+strconv.Itoa(rowindex), tgdata.Port)
				f.SetCellValue(title, "G"+strconv.Itoa(rowindex), tgdata.TargetARN)
				f.SetCellValue(title, "K"+strconv.Itoa(rowindex), tgdata.TargetIDs)
				f.SetCellValue(title, "L"+strconv.Itoa(rowindex), tgdata.HealthCheckProtocol)
				f.SetCellValue(title, "M"+strconv.Itoa(rowindex), tgdata.HealthCheckPort)
				f.SetCellValue(title, "N"+strconv.Itoa(rowindex), tgdata.HealthCheckPath)
				f.SetCellValue(title, "O"+strconv.Itoa(rowindex), tgdata.HealthCheckTimeoutSeconds)
				f.SetCellValue(title, "P"+strconv.Itoa(rowindex), tgdata.HealthCheckThresholdCount)
				f.SetCellValue(title, "Q"+strconv.Itoa(rowindex), tgdata.UnhealthyThresholdCount)
				rowindex++
			}
		*/

	}

	return rowindex
}

func MakeTargetGroupColumn(f *excelize.File, title string, rowindex int, resource string) int { // 엑셀에 타겟 그룹에 대한 실제 데이터 입력

	style := ColumnStyle(f)

	f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "H"+strconv.Itoa(rowindex), style)
	f.SetCellValue(title, "B"+strconv.Itoa(rowindex), "Account")
	f.SetCellValue(title, "C"+strconv.Itoa(rowindex), "Service")
	f.SetCellValue(title, "D"+strconv.Itoa(rowindex), "TG Name")
	f.SetCellValue(title, "E"+strconv.Itoa(rowindex), "TG Protocol")
	f.SetCellValue(title, "F"+strconv.Itoa(rowindex), "TG Port")
	f.SetCellValue(title, "G"+strconv.Itoa(rowindex), "LB ARN")
	f.SetCellValue(title, "H"+strconv.Itoa(rowindex), "TG TargetARN")
	/*
		f.SetCellValue(title, "H"+strconv.Itoa(rowindex), "TG Listener ARN")
		f.SetCellValue(title, "I"+strconv.Itoa(rowindex), "Condition")
		f.SetCellValue(title, "J"+strconv.Itoa(rowindex), "Sticky Enabled")
		f.SetCellValue(title, "K"+strconv.Itoa(rowindex), "Target IDs")

		f.SetCellValue(title, "L"+strconv.Itoa(rowindex), "TG HealthCheck Protocol")
		f.SetCellValue(title, "M"+strconv.Itoa(rowindex), "TG HealthCheck Port")
		f.SetCellValue(title, "N"+strconv.Itoa(rowindex), "TG HealthCheck Path")
		f.SetCellValue(title, "O"+strconv.Itoa(rowindex), "TG HealthCheck Timeout Seconds")
		f.SetCellValue(title, "P"+strconv.Itoa(rowindex), "TG HealthCheck Threshold Count")
		f.SetCellValue(title, "Q"+strconv.Itoa(rowindex), "TG Unhealthy Threshold Count")
	*/
	return rowindex + 1
}

func MakeTargetGroupSubtitle(f *excelize.File, title string, subtitle string, rowindex int) int { // 엑셀에 타겟 그룹이라는 소주제 입력
	err := f.MergeCell(title, "B"+strconv.Itoa(rowindex), "D"+strconv.Itoa(rowindex))
	if err != nil {
		log.Printf("Make SubTitle Error: %s", err.Error())
	}
	style, index := SubtitleStyle(f, rowindex)
	f.SetCellStyle(title, "B"+strconv.Itoa(index), "D"+strconv.Itoa(index), style)
	f.SetCellValue(title, "B"+strconv.Itoa(index), subtitle)
	return index + 2
}

func MakeLBValue(f *excelize.File, title string, rowindex int, accountName *string, result []*LoadBalancerData, resource string) int { // 엑셀에 LB 실제 데이터 입력
	for _, lbdata := range result {

		style := ValueStyle(f)

		f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "G"+strconv.Itoa(rowindex), style)
		f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
		f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
		f.SetCellValue(title, "D"+strconv.Itoa(rowindex), lbdata.Name)
		f.SetCellValue(title, "E"+strconv.Itoa(rowindex), lbdata.InExternal)
		f.SetCellValue(title, "F"+strconv.Itoa(rowindex), lbdata.PrdDev)
		f.SetCellValue(title, "G"+strconv.Itoa(rowindex), lbdata.Type)
		rowindex++
	}

	return rowindex
}

func MakeLBColumn(f *excelize.File, title string, rowindex int, resource string) int { // 엑셀에 LB 실제 데이터에 대한 제목 입력

	style := ColumnStyle(f)

	f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "G"+strconv.Itoa(rowindex), style)
	f.SetCellValue(title, "B"+strconv.Itoa(rowindex), "Account")
	f.SetCellValue(title, "C"+strconv.Itoa(rowindex), "Service")
	f.SetCellValue(title, "D"+strconv.Itoa(rowindex), "LB Name")
	f.SetCellValue(title, "E"+strconv.Itoa(rowindex), "LB Scheme")
	f.SetCellValue(title, "F"+strconv.Itoa(rowindex), "LB Usage")
	f.SetCellValue(title, "G"+strconv.Itoa(rowindex), "LB Type")

	return rowindex + 1
}

func MakeLBSubtitle(f *excelize.File, title string, subtitle string, rowindex int) int { // 엑셀에 Load Balancer라는 소주제 입력
	err := f.MergeCell(title, "B"+strconv.Itoa(rowindex), "D"+strconv.Itoa(rowindex))
	if err != nil {
		log.Printf("Make SubTitle Error: %s", err.Error())
	}
	style, index := SubtitleStyle(f, rowindex)
	f.SetCellStyle(title, "B"+strconv.Itoa(index), "D"+strconv.Itoa(index), style)
	f.SetCellValue(title, "B"+strconv.Itoa(index), subtitle)
	return index + 2
}

func MakeEIPValue(f *excelize.File, title string, rowindex int, accountName *string, result []*EIPData, resource string) int { //엑셀에 EIP 실제 데이터 입력
	for _, data := range result {

		style := ValueStyle(f)

		f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "E"+strconv.Itoa(rowindex), style)
		f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
		f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
		f.SetCellValue(title, "D"+strconv.Itoa(rowindex), data.IPAddress)
		f.SetCellValue(title, "E"+strconv.Itoa(rowindex), data.AssociationId)
		rowindex++
	}

	return rowindex
}

func MakeEIPColumn(f *excelize.File, title string, rowindex int, resource string) int { // 엑셀에 EIP 실제 데이터에 대한 제목 입력

	style := ColumnStyle(f)

	f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "E"+strconv.Itoa(rowindex), style)
	f.SetCellValue(title, "B"+strconv.Itoa(rowindex), "Account")
	f.SetCellValue(title, "C"+strconv.Itoa(rowindex), "Service")
	f.SetCellValue(title, "D"+strconv.Itoa(rowindex), "IP Address")
	f.SetCellValue(title, "E"+strconv.Itoa(rowindex), "Association ID")

	return rowindex + 1
}

func MakeEIPSubtitle(f *excelize.File, title string, subtitle string, rowindex int) int { // 엑셀에 EIP라는 소주제 입력
	err := f.MergeCell(title, "B"+strconv.Itoa(rowindex), "D"+strconv.Itoa(rowindex))
	if err != nil {
		log.Printf("Make SubTitle Error: %s", err.Error())
	}
	style, index := SubtitleStyle(f, rowindex)
	f.SetCellStyle(title, "B"+strconv.Itoa(index), "D"+strconv.Itoa(index), style)
	f.SetCellValue(title, "B"+strconv.Itoa(index), subtitle)
	return index + 2
}

func MakeEBSValue(f *excelize.File, title string, rowindex int, accountName *string, result []*EBSData, resource string) int { //엑셀에 EBS 실제 데이터 입력
	for _, data := range result {

		style := ValueStyle(f)

		f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "I"+strconv.Itoa(rowindex), style)
		f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
		f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
		f.SetCellValue(title, "D"+strconv.Itoa(rowindex), data.ID)
		f.SetCellValue(title, "E"+strconv.Itoa(rowindex), data.Name)
		f.SetCellValue(title, "F"+strconv.Itoa(rowindex), data.Type)
		f.SetCellValue(title, "G"+strconv.Itoa(rowindex), data.IOPS)
		f.SetCellValue(title, "H"+strconv.Itoa(rowindex), data.Size)
		f.SetCellValue(title, "I"+strconv.Itoa(rowindex), data.State)

		rowindex++
	}

	return rowindex
}

func MakeEBSColumn(f *excelize.File, title string, rowindex int, resource string) int { // 엑셀에 EBS 실제 데이터에 대한 제목 입력

	style := ColumnStyle(f)

	f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "I"+strconv.Itoa(rowindex), style)
	f.SetCellValue(title, "B"+strconv.Itoa(rowindex), "Account")
	f.SetCellValue(title, "C"+strconv.Itoa(rowindex), "Service")
	f.SetCellValue(title, "D"+strconv.Itoa(rowindex), "ID")
	f.SetCellValue(title, "E"+strconv.Itoa(rowindex), "Name")
	f.SetCellValue(title, "F"+strconv.Itoa(rowindex), "Type")
	f.SetCellValue(title, "G"+strconv.Itoa(rowindex), "IOPS")
	f.SetCellValue(title, "H"+strconv.Itoa(rowindex), "Size")
	f.SetCellValue(title, "I"+strconv.Itoa(rowindex), "State")

	return rowindex + 1
}

func MakeEBSSubtitle(f *excelize.File, title string, subtitle string, rowindex int) int { //엑셀에 EBS라는 소주제 입력
	err := f.MergeCell(title, "B"+strconv.Itoa(rowindex), "D"+strconv.Itoa(rowindex))
	if err != nil {
		log.Printf("Make SubTitle Error: %s", err.Error())
	}
	style, index := SubtitleStyle(f, rowindex)
	f.SetCellStyle(title, "B"+strconv.Itoa(index), "D"+strconv.Itoa(index), style)
	f.SetCellValue(title, "B"+strconv.Itoa(index), subtitle)
	return index + 2
}

////////////////////////////////////EKS //////////////////////////////////////////

func MakeEKSValue(f *excelize.File, title string, rowindex int, accountName *string, result []*EKSData, resource string) int { //엑셀에 EKS 실제 데이터 입력
	style := ValueStyle(f)
	for _, eksdata := range result {
		for _, nodedata := range eksdata.NodeGroupData {
			f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "J"+strconv.Itoa(rowindex), style)
			f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
			f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
			f.SetCellValue(title, "D"+strconv.Itoa(rowindex), eksdata.ClusterName)
			f.SetCellValue(title, "E"+strconv.Itoa(rowindex), nodedata.Version)
			f.SetCellValue(title, "F"+strconv.Itoa(rowindex), nodedata.InstanceTypes)
			f.SetCellValue(title, "G"+strconv.Itoa(rowindex), nodedata.NodeGroupName)
			f.SetCellValue(title, "H"+strconv.Itoa(rowindex), nodedata.DiskSize)
			f.SetCellValue(title, "I"+strconv.Itoa(rowindex), nodedata.Min)
			f.SetCellValue(title, "J"+strconv.Itoa(rowindex), nodedata.Max)
			rowindex++
		}
	}

	return rowindex
}

func MakeEKSColumn(f *excelize.File, title string, rowindex int, resource string) int { // 엑셀에 EKS 실제 데이터에 대한 제목 입력

	style := ColumnStyle(f)

	f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "J"+strconv.Itoa(rowindex), style)
	f.SetCellValue(title, "B"+strconv.Itoa(rowindex), "Account")
	f.SetCellValue(title, "C"+strconv.Itoa(rowindex), "Service")
	f.SetCellValue(title, "D"+strconv.Itoa(rowindex), "Cluster Name")
	f.SetCellValue(title, "E"+strconv.Itoa(rowindex), "Version")
	f.SetCellValue(title, "F"+strconv.Itoa(rowindex), "Instance Type")
	f.SetCellValue(title, "G"+strconv.Itoa(rowindex), "NodeGroupName")
	f.SetCellValue(title, "H"+strconv.Itoa(rowindex), "Disk Size(GB)")
	f.SetCellValue(title, "I"+strconv.Itoa(rowindex), "Min")
	f.SetCellValue(title, "J"+strconv.Itoa(rowindex), "Max")

	return rowindex + 1
}

func MakeEKSSubtitle(f *excelize.File, title string, subtitle string, rowindex int) int { // 엑셀에 EKS라는 소주제 입력
	err := f.MergeCell(title, "B"+strconv.Itoa(rowindex), "J"+strconv.Itoa(rowindex))
	if err != nil {
		log.Printf("Make SubTitle Error: %s", err.Error())
	}
	style, index := SubtitleStyle(f, rowindex)
	f.SetCellStyle(title, "B"+strconv.Itoa(index), "J"+strconv.Itoa(index), style)
	f.SetCellValue(title, "B"+strconv.Itoa(index), subtitle)
	return index + 2
}

///////////////////////////////////////////EC2 Count /////////////////////////////////////////////////////

func MakeEC2CountValue(f *excelize.File, title string, rowindex int, accountName *string, result *ResultResource, resource string) int { // 엑셀에 EC2 집계 데이터 입력
	style := ValueStyle(f)

	f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "E"+strconv.Itoa(rowindex), style)
	f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
	f.SetCellValue(title, "C"+strconv.Itoa(rowindex), result.EC2Running)
	f.SetCellValue(title, "D"+strconv.Itoa(rowindex), result.EC2Stopped)
	f.SetCellValue(title, "E"+strconv.Itoa(rowindex), result.EC2Running+result.EC2Stopped)

	rowindex++

	return rowindex
}

func MakeEC2CountColumn(f *excelize.File, title string, rowindex int, resource string) int { // 엑셀에 EC2 집계 데이터에 대한 제목 입력

	style := ColumnStyle(f)

	f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "E"+strconv.Itoa(rowindex), style)
	f.SetCellValue(title, "B"+strconv.Itoa(rowindex), "Account")
	f.SetCellValue(title, "C"+strconv.Itoa(rowindex), "Running")
	f.SetCellValue(title, "D"+strconv.Itoa(rowindex), "Stopped")
	f.SetCellValue(title, "E"+strconv.Itoa(rowindex), "Total")

	return rowindex + 1
}

func MakeEC2CountSubtitle(f *excelize.File, title string, subtitle string, rowindex int) int { // 엑셀에 EC2 집계 데이터에 대한 소주제 입력
	err := f.MergeCell(title, "B"+strconv.Itoa(rowindex), "D"+strconv.Itoa(rowindex))
	if err != nil {
		log.Printf("Make SubTitle Error: %s", err.Error())
	}
	style, index := SubtitleStyle(f, rowindex)
	f.SetCellStyle(title, "B"+strconv.Itoa(index), "D"+strconv.Itoa(index), style)
	f.SetCellValue(title, "B"+strconv.Itoa(index), subtitle)
	return index + 2
}

/////////////////////////////////////////EC2 /////////////////////////////////////////////////////////////

func MakeEC2Value(f *excelize.File, title string, rowindex int, accountName *string, result []*EC2Data, resource string) int { // 엑셀에 EC2에 대한 실제 데이터 입력
	for _, instance := range result {

		style := ValueStyle(f)

		f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "M"+strconv.Itoa(rowindex), style)
		f.SetCellStyle(title, "O"+strconv.Itoa(rowindex), "X"+strconv.Itoa(rowindex), style)
		if len(instance.RIData) > 1 { // RI 데이터가 1개보다 많을 때
			for i := 0; i < 12; i++ {
				err := f.MergeCell(title, string(toChar(i+2))+strconv.Itoa(rowindex), string(toChar(i+2))+strconv.Itoa(rowindex+len(instance.RIData))) //RI가 복수개 할당시 해당 인스턴스에 대한 정보를 RI 개수만큼 행을 합침
				if err != nil {
					log.Printf("Make SubTitle Error: %s", err.Error())
				}
			}

			f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
			f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
			f.SetCellValue(title, "D"+strconv.Itoa(rowindex), instance.InstanceName)
			f.SetCellValue(title, "E"+strconv.Itoa(rowindex), instance.Hostname)
			f.SetCellValue(title, "F"+strconv.Itoa(rowindex), instance.InstanceId)
			f.SetCellValue(title, "G"+strconv.Itoa(rowindex), instance.InstanceType)
			f.SetCellValue(title, "H"+strconv.Itoa(rowindex), instance.OSVersion)
			f.SetCellValue(title, "I"+strconv.Itoa(rowindex), instance.PrivateIP)
			f.SetCellValue(title, "J"+strconv.Itoa(rowindex), instance.Status)
			f.SetCellValue(title, "K"+strconv.Itoa(rowindex), instance.Usage)
			f.SetCellValue(title, "L"+strconv.Itoa(rowindex), instance.Site)
			f.SetCellValue(title, "M"+strconv.Itoa(rowindex), instance.DBSafer)

			for i := 0; i < len(instance.RIData); i++ {
				if instance.RIData[i].RIEnd.Before(time.Now().AddDate(0, 3, 0)) {
					colorstyle := ValueColorStyle(f)
					f.SetCellStyle(title, "O"+strconv.Itoa(rowindex), "X"+strconv.Itoa(rowindex), colorstyle)
				}
				f.SetCellValue(title, "O"+strconv.Itoa(rowindex), instance.RIData[i].RIID)
				f.SetCellValue(title, "P"+strconv.Itoa(rowindex), instance.RIData[i].RIStart.Format("2006-01-02 15:04:05"))
				f.SetCellValue(title, "Q"+strconv.Itoa(rowindex), instance.RIData[i].RIEnd.Format("2006-01-02 15:04:05"))
				f.SetCellValue(title, "R"+strconv.Itoa(rowindex), instance.RIData[i].Platform)
				f.SetCellValue(title, "S"+strconv.Itoa(rowindex), instance.RIData[i].Tenancy)
				f.SetCellValue(title, "T"+strconv.Itoa(rowindex), instance.RIData[i].OfferingClass)
				f.SetCellValue(title, "U"+strconv.Itoa(rowindex), instance.RIData[i].OfferingType)
				f.SetCellValue(title, "V"+strconv.Itoa(rowindex), instance.RIData[i].RIInstanceType)
				f.SetCellValue(title, "W"+strconv.Itoa(rowindex), instance.RIData[i].Term)
				f.SetCellValue(title, "X"+strconv.Itoa(rowindex), instance.RIData[i].Count)
				rowindex++
			}

		} else if instance.RIData == nil { // RI가 없을 경우
			f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
			f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
			f.SetCellValue(title, "D"+strconv.Itoa(rowindex), instance.InstanceName)
			f.SetCellValue(title, "E"+strconv.Itoa(rowindex), instance.Hostname)
			f.SetCellValue(title, "F"+strconv.Itoa(rowindex), instance.InstanceId)
			f.SetCellValue(title, "G"+strconv.Itoa(rowindex), instance.InstanceType)
			f.SetCellValue(title, "H"+strconv.Itoa(rowindex), instance.OSVersion)
			f.SetCellValue(title, "I"+strconv.Itoa(rowindex), instance.PrivateIP)
			f.SetCellValue(title, "J"+strconv.Itoa(rowindex), instance.Status)
			f.SetCellValue(title, "K"+strconv.Itoa(rowindex), instance.Usage)
			f.SetCellValue(title, "L"+strconv.Itoa(rowindex), instance.Site)
			f.SetCellValue(title, "M"+strconv.Itoa(rowindex), instance.DBSafer)
			rowindex++
		} else { // RI가 1개 일때
			if instance.RIData[0].RIEnd.Before(time.Now().AddDate(0, 3, 0)) {
				colorstyle := ValueColorStyle(f)
				f.SetCellStyle(title, "O"+strconv.Itoa(rowindex), "X"+strconv.Itoa(rowindex), colorstyle)
			}
			f.SetCellValue(title, "B"+strconv.Itoa(rowindex), *accountName)
			f.SetCellValue(title, "C"+strconv.Itoa(rowindex), title)
			f.SetCellValue(title, "D"+strconv.Itoa(rowindex), instance.InstanceName)
			f.SetCellValue(title, "E"+strconv.Itoa(rowindex), instance.Hostname)
			f.SetCellValue(title, "F"+strconv.Itoa(rowindex), instance.InstanceId)
			f.SetCellValue(title, "G"+strconv.Itoa(rowindex), instance.InstanceType)
			f.SetCellValue(title, "H"+strconv.Itoa(rowindex), instance.OSVersion)
			f.SetCellValue(title, "I"+strconv.Itoa(rowindex), instance.PrivateIP)
			f.SetCellValue(title, "J"+strconv.Itoa(rowindex), instance.Status)
			f.SetCellValue(title, "K"+strconv.Itoa(rowindex), instance.Usage)
			f.SetCellValue(title, "L"+strconv.Itoa(rowindex), instance.Site)
			f.SetCellValue(title, "M"+strconv.Itoa(rowindex), instance.DBSafer)

			f.SetCellValue(title, "O"+strconv.Itoa(rowindex), instance.RIData[0].RIID)
			f.SetCellValue(title, "P"+strconv.Itoa(rowindex), instance.RIData[0].RIStart.Format("2006-01-02 15:04:05"))
			f.SetCellValue(title, "Q"+strconv.Itoa(rowindex), instance.RIData[0].RIEnd.Format("2006-01-02 15:04:05"))
			f.SetCellValue(title, "R"+strconv.Itoa(rowindex), instance.RIData[0].Platform)
			f.SetCellValue(title, "S"+strconv.Itoa(rowindex), instance.RIData[0].Tenancy)
			f.SetCellValue(title, "T"+strconv.Itoa(rowindex), instance.RIData[0].OfferingClass)
			f.SetCellValue(title, "U"+strconv.Itoa(rowindex), instance.RIData[0].OfferingType)
			f.SetCellValue(title, "V"+strconv.Itoa(rowindex), instance.RIData[0].RIInstanceType)
			f.SetCellValue(title, "W"+strconv.Itoa(rowindex), instance.RIData[0].Term)
			f.SetCellValue(title, "X"+strconv.Itoa(rowindex), instance.RIData[0].Count)
			rowindex++
		}

	}

	return rowindex
}

func MakeEC2Column(f *excelize.File, title string, rowindex int, resource string) int { // 엑셀에 EC2 실제 데이터에 대한 제목 입력

	style := ColumnStyle(f)

	f.SetCellStyle(title, "B"+strconv.Itoa(rowindex), "M"+strconv.Itoa(rowindex), style)
	f.SetCellStyle(title, "O"+strconv.Itoa(rowindex), "X"+strconv.Itoa(rowindex), style)
	f.SetCellValue(title, "B"+strconv.Itoa(rowindex), "Account")
	f.SetCellValue(title, "C"+strconv.Itoa(rowindex), "Service")
	f.SetCellValue(title, "D"+strconv.Itoa(rowindex), "ServerName")
	f.SetCellValue(title, "E"+strconv.Itoa(rowindex), "Hostname")
	f.SetCellValue(title, "F"+strconv.Itoa(rowindex), "Instance ID")
	f.SetCellValue(title, "G"+strconv.Itoa(rowindex), "Instance Type")
	f.SetCellValue(title, "H"+strconv.Itoa(rowindex), "OS Version")
	f.SetCellValue(title, "I"+strconv.Itoa(rowindex), "Private IP")
	f.SetCellValue(title, "J"+strconv.Itoa(rowindex), "State")
	f.SetCellValue(title, "K"+strconv.Itoa(rowindex), "Usage")
	f.SetCellValue(title, "L"+strconv.Itoa(rowindex), "Site")
	f.SetCellValue(title, "M"+strconv.Itoa(rowindex), "DB Safer")

	f.SetCellValue(title, "O"+strconv.Itoa(rowindex), "RI ID")
	f.SetCellValue(title, "P"+strconv.Itoa(rowindex), "Start")
	f.SetCellValue(title, "Q"+strconv.Itoa(rowindex), "End")
	f.SetCellValue(title, "R"+strconv.Itoa(rowindex), "Platform")
	f.SetCellValue(title, "S"+strconv.Itoa(rowindex), "Tenancy")
	f.SetCellValue(title, "T"+strconv.Itoa(rowindex), "Offering Class")
	f.SetCellValue(title, "U"+strconv.Itoa(rowindex), "Offering Type")
	f.SetCellValue(title, "V"+strconv.Itoa(rowindex), "Instance Type")
	f.SetCellValue(title, "W"+strconv.Itoa(rowindex), "Term")
	f.SetCellValue(title, "X"+strconv.Itoa(rowindex), "Count")

	return rowindex + 1
}

func MakeEC2Subtitle(f *excelize.File, title string, subtitle string, rowindex int) int { // 엑셀에 EC2라는 소주제 입력
	err := f.MergeCell(title, "B"+strconv.Itoa(rowindex), "D"+strconv.Itoa(rowindex))
	if err != nil {
		log.Printf("Make SubTitle Error: %s", err.Error())
	}
	style, index := SubtitleStyle(f, rowindex)
	f.SetCellStyle(title, "B"+strconv.Itoa(index), "D"+strconv.Itoa(index), style)
	f.SetCellValue(title, "B"+strconv.Itoa(index), subtitle)
	return index + 2
}

/////////////////////////////////////// Excelize //////////////////////////////////////////////////////

func MakeExcelReport(title string, resultresources []*ResultResource) (string, *excelize.File) { // 엑셀을 만드는 함수
	f := excelize.NewFile(excelize.Options{})
	f.SetSheetName("Sheet1", "Default")
	defer func() {
		if err := f.Close(); err != nil {
			log.Printf("MakeExcelReport Error: %s", err.Error())
		}
	}()
	sheetTitles := []string{"EC2", "EC2Count", "EIP", "EBS", "SG", "VPC", "Subnet", "VPN", "LB", "TargetGroup", "NatGateway", "S3", "EKS", "RDS", "Cloudwatch Alarm", "Cloudfront"} // 엑셀에 넣을 리소스 정보들 리스트
	for _, sheetTitle := range sheetTitles {                                                                                                                                        // 위에 출력될 리소스 대상들을 순서대로 설정
		// 워크시트 만들기

		_, err := f.NewSheet(sheetTitle) //출력될 리소스에 대한 엑셀 시트 명
		if err != nil {
			log.Printf("MakeExcelReport Error: %s", err.Error())
			return "", nil
		}
		// 셀 값 설정
		rowindex := 1
		switch sheetTitle {
		case "EC2": //sheetTitles에 대한 for 반복문에서 첫번째인 EC2일 경우 EC2 데이터에 대한 엑셀시트 생성

			rowindex = MakeEC2Subtitle(f, sheetTitle, "1) EC2", rowindex) // 1) EC2라는 소주제를 생성하는 함수
			rowindex = MakeEC2Column(f, sheetTitle, rowindex, "ec2")      // EC2 시트에 포함될 정보에 대한 제목 설정
			for _, resultdata := range resultresources {                  // EC2에 대한 실제 데이터를 엑셀에 넣는 반복문
				if len(resultdata.EC2) != 0 { // 계정별 EC2정보가 1개라도 있을 경우에 대한 조건문
					rowindex = MakeEC2Value(f, sheetTitle, rowindex, &resultdata.AccountName, resultdata.EC2, "ec2") // 각 EC2에 대한 정보를 엑셀에 기입하는 함수
				}
			}

		case "EC2Count": // EC2 집계 데이터에 대한 엑셀 시트 생성

			rowindex = MakeEC2CountSubtitle(f, sheetTitle, "2) EC2 Count", rowindex)
			rowindex = MakeEC2CountColumn(f, sheetTitle, rowindex, "ec2count")
			for _, resultdata := range resultresources {
				rowindex = MakeEC2CountValue(f, sheetTitle, rowindex, &resultdata.AccountName, resultdata, "ec2")
				//ResultResource에 저장된 데이터를 엑셀에 넣는 함수
			}

		case "EIP": //EIP 데이터에 대한 엑셀 시트 생성

			rowindex = MakeEIPSubtitle(f, sheetTitle, "3) EIP", rowindex)
			rowindex = MakeEIPColumn(f, sheetTitle, rowindex, "eip")
			for _, resultdata := range resultresources {
				if len(resultdata.EIPData) != 0 {
					rowindex = MakeEIPValue(f, sheetTitle, rowindex, &resultdata.AccountName, resultdata.EIPData, "eip")
					//ResultResource에 저장된 데이터를 엑셀에 넣는 함수
				}
			}

		case "EBS": //EBS 데이터에 대한 엑셀 시트 생성

			rowindex = MakeEBSSubtitle(f, sheetTitle, "4) EBS", rowindex)
			rowindex = MakeEBSColumn(f, sheetTitle, rowindex, "ebs")
			for _, resultdata := range resultresources {
				if len(resultdata.EBSData) != 0 {
					rowindex = MakeEBSValue(f, sheetTitle, rowindex, &resultdata.AccountName, resultdata.EBSData, "ebs")
					//ResultResource에 저장된 데이터를 엑셀에 넣는 함수
				}
			}

		case "SG": // Security Group에 대한 엑셀시트 생성

			rowindex = MakeSGSubtitle(f, sheetTitle, "5) SG", rowindex)
			rowindex = MakeSGColumn(f, sheetTitle, rowindex, "sg")
			for _, resultdata := range resultresources {
				if len(resultdata.SecurityGroupRuleData) != 0 {
					rowindex = MakeSGValue(f, sheetTitle, rowindex, &resultdata.AccountName, resultdata.SecurityGroupRuleData, "sg")
					//ResultResource에 저장된 데이터를 엑셀에 넣는 함수
				}
			}
		case "VPC": //VPC 데이터에 대한 엑셀 시트 생성

			rowindex = MakeVPCSubtitle(f, sheetTitle, "6) VPC", rowindex)
			rowindex = MakeVPCColumn(f, sheetTitle, rowindex, "vpc")
			for _, resultdata := range resultresources {
				if len(resultdata.VPCData) != 0 {
					rowindex = MakeVPCValue(f, sheetTitle, rowindex, &resultdata.AccountName, resultdata.VPCData, "vpc")
					//ResultResource에 저장된 데이터를 엑셀에 넣는 함수
				}
			}
		case "Subnet": //Subnet 데이터에 대한 엑셀 시트 생성

			rowindex = MakeSubnetSubtitle(f, sheetTitle, "7) Subnet", rowindex)
			rowindex = MakeSubnetColumn(f, sheetTitle, rowindex, "subnet")
			for _, resultdata := range resultresources {
				if len(resultdata.SubnetData) != 0 {
					rowindex = MakeSubnetValue(f, sheetTitle, rowindex, &resultdata.AccountName, resultdata.SubnetData, "subnet")
					//ResultResource에 저장된 데이터를 엑셀에 넣는 함수
				}
			}

		case "VPN": //VPN 데이터에 대한 엑셀 시트 생성

			rowindex = MakeVPNSubtitle(f, sheetTitle, "8) VPN", rowindex)
			rowindex = MakeVPNColumn(f, sheetTitle, rowindex, "vpn")
			for _, resultdata := range resultresources {
				if len(resultdata.VPN) != 0 {
					rowindex = MakeVPNValue(f, sheetTitle, rowindex, &resultdata.AccountName, resultdata.VPN, "vpn")
					//ResultResource에 저장된 데이터를 엑셀에 넣는 함수
				}
			}

		case "LB": //Load Balancer 데이터에 대한 엑셀 시트 생성

			rowindex = MakeLBSubtitle(f, sheetTitle, "9) LB", rowindex)
			rowindex = MakeLBColumn(f, sheetTitle, rowindex, "lb")
			for _, resultdata := range resultresources {
				if len(resultdata.LB) != 0 {
					rowindex = MakeLBValue(f, sheetTitle, rowindex, &resultdata.AccountName, resultdata.LB, "lb")
					//ResultResource에 저장된 데이터를 엑셀에 넣는 함수
				}
			}

		case "TargetGroup": //Target Group 데이터에 대한 엑셀 시트 생성

			rowindex = MakeTargetGroupSubtitle(f, sheetTitle, "10) Target Group", rowindex)
			rowindex = MakeTargetGroupColumn(f, sheetTitle, rowindex, "tg")
			for _, resultdata := range resultresources {
				if len(resultdata.LB) != 0 {
					rowindex = MakeTargetGroupValue(f, sheetTitle, rowindex, &resultdata.AccountName, resultdata.TargetGroupData, "tg")
					//ResultResource에 저장된 데이터를 엑셀에 넣는 함수
				}
			}

		case "NatGateway": //NAT Gateway 데이터에 대한 엑셀 시트 생성

			rowindex = MakeNatGatewaySubtitle(f, sheetTitle, "11) NAT Gateawy", rowindex)
			rowindex = MakeNatGatewayColumn(f, sheetTitle, rowindex, "ngw")
			for _, resultdata := range resultresources {
				if len(resultdata.NatGatewayData) != 0 {
					rowindex = MakeNatGatewayValue(f, sheetTitle, rowindex, &resultdata.AccountName, resultdata.NatGatewayData, "ngw")
					//ResultResource에 저장된 데이터를 엑셀에 넣는 함수
				}
			}

		case "S3": //S3 데이터에 대한 엑셀 시트 생성

			rowindex = MakeS3Subtitle(f, sheetTitle, "12) S3", rowindex)
			rowindex = MakeS3Column(f, sheetTitle, rowindex, "s3")
			for _, resultdata := range resultresources {
				if len(resultdata.S3Data) != 0 {
					rowindex = MakeS3Value(f, sheetTitle, rowindex, &resultdata.AccountName, resultdata.S3Data, "s3")
					//ResultResource에 저장된 데이터를 엑셀에 넣는 함수
				}
			}

		case "EKS": //EKS 데이터에 대한 엑셀 시트 생성

			rowindex = MakeEKSSubtitle(f, sheetTitle, "13) EKS", rowindex)
			rowindex = MakeEKSColumn(f, sheetTitle, rowindex, "eks")
			for _, resultdata := range resultresources {
				if len(resultdata.EKSData) != 0 {
					rowindex = MakeEKSValue(f, sheetTitle, rowindex, &resultdata.AccountName, resultdata.EKSData, "eks")
					//ResultResource에 저장된 데이터를 엑셀에 넣는 함수
				}
			}

		case "RDS": //RDS 데이터에 대한 엑셀 시트 생성

			rowindex = MakeClusterSubtitle(f, sheetTitle, "14) Cluster", rowindex)

			for _, resultdata := range resultresources {
				if len(resultdata.ClusterData) != 0 {
					rowindex = MakeClusterValue(f, sheetTitle, rowindex, &resultdata.AccountName, resultdata.ClusterData, "rds")
					//ResultResource에 저장된 데이터를 엑셀에 넣는 함수
				}
			}

			rowindex = MakeRDSSubtitle(f, sheetTitle, "15) RDS", rowindex)
			rowindex = MakeRDSColumn(f, sheetTitle, rowindex, "rds")
			for _, resultdata := range resultresources {
				if len(resultdata.RDSData) != 0 {
					rowindex = MakeRDSValue(f, sheetTitle, rowindex, &resultdata.AccountName, resultdata.RDSData, "rds")
					//ResultResource에 저장된 데이터를 엑셀에 넣는 함수
				}
			}

		case "Cloudwatch Alarm": //Cloudwatch Alarm 데이터에 대한 엑셀 시트 생성

			rowindex = MakeCloudwatchAlarmSubtitle(f, sheetTitle, "16) Cloudwatch Alarm", rowindex)
			rowindex = MakeCloudwatchAlarmColumn(f, sheetTitle, rowindex, "cloudwatchalarm")
			for _, resultdata := range resultresources {
				if len(resultdata.S3Data) != 0 {
					rowindex = MakeCloudwatchAlarmValue(f, sheetTitle, rowindex, &resultdata.AccountName, resultdata.CloudwatchAlarmData, "cloudwatchalarm")
					//ResultResource에 저장된 데이터를 엑셀에 넣는 함수
				}
			}

		case "Cloudfront": //Cloudfront 데이터에 대한 엑셀 시트 생성

			rowindex = MakeCloudfrontSubtitle(f, sheetTitle, "17) Cloudfront", rowindex)
			rowindex = MakeCloudfrontColumn(f, sheetTitle, rowindex, "cloudfront")
			for _, resultdata := range resultresources {
				if len(resultdata.S3Data) != 0 {
					rowindex = MakeCloudfrontValue(f, sheetTitle, rowindex, &resultdata.AccountName, resultdata.CFData, "cloudfront")
					//ResultResource에 저장된 데이터를 엑셀에 넣는 함수
				}
			}

		default:

		}

	}

	// 통합 문서에 대 한 기본 워크시트를 설정 합니다
	f.SetActiveSheet(0)
	// 지정 된 경로를 기반으로 파일 저장
	f.DeleteSheet("Default")
	filename := title + getDateString(time.Now().Year()) + "_" + getDateString(int(time.Now().Month())) + getDateString(time.Now().Day()) + ".xlsx"

	return filename, f
}

// 월 표시 시 3월 -> 03월처럼 앞자리에 0을 추가하는 함수
func getDateString(date int) string {
	if date < 10 {
		return "0" + strconv.Itoa(date) //매개변수 숫자가 10보다 작으면 앞에 0을 추가
	} else {
		return strconv.Itoa(date)
	}
}

// 엑셀에 들어가는 실제 데이터 부분의 엑셀 스타일 설정 (RI)
// https://xuri.me/excelize/ko/cell.html#SetCellStyle
func ValueColorStyle(f *excelize.File) int {
	bordersetting := make([]excelize.Border, 0)            // 테두리 객체 생성
	bordersetting = append(bordersetting, excelize.Border{ //테두리 객체 왼쪽에 대한 설정 추가
		Type:  "left",
		Style: 2,
		Color: "#000000",
	})
	bordersetting = append(bordersetting, excelize.Border{ //테두리 객체 오른쪽에 대한 설정 추가
		Type:  "right",
		Style: 2,
		Color: "#000000",
	})
	bordersetting = append(bordersetting, excelize.Border{ //테두리 객체 위에 대한 설정 추가
		Type:  "top",
		Style: 2,
		Color: "#000000",
	})
	bordersetting = append(bordersetting, excelize.Border{ //테두리 객체 아래에 대한 설정 추가
		Type:  "bottom",
		Style: 2,
		Color: "#000000",
	})

	style, err := f.NewStyle(&excelize.Style{ // 실제 엑셀 칸에 대한 스타일 객체 생성
		Border: bordersetting, //위에 추가한 테두리 설정 추가
		Fill: excelize.Fill{
			Type: "pattern", Color: []string{"E0EBF5"}, Pattern: 1, // 채우기 설정 색, 패턴 등
		},
		Alignment: &excelize.Alignment{ // 스타일이 적용될 칸에 대한 정렬방식
			Horizontal: "center",
			Vertical:   "center",
		},
		Font: &excelize.Font{ // 스타일이 적용될 칸에 대한 Bold 설정 여부 및 폰트 사이즈
			Bold: false,
			Size: 10,
		},
	})
	if err != nil {
		log.Printf("MakeValue Error: %s", err.Error())
		return 0
	}
	return style
}

// 엑셀에 들어가는 실제 데이터 부분의 엑셀 스타일 설정
func ValueStyle(f *excelize.File) int {
	bordersetting := make([]excelize.Border, 0)
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "left",
		Style: 2,
		Color: "#000000",
	})
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "right",
		Style: 2,
		Color: "#000000",
	})
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "top",
		Style: 2,
		Color: "#000000",
	})
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "bottom",
		Style: 2,
		Color: "#000000",
	})

	style, err := f.NewStyle(&excelize.Style{
		Border: bordersetting,
		Alignment: &excelize.Alignment{
			Horizontal: "center",
			Vertical:   "center",
		},
		Font: &excelize.Font{
			Bold: false,
			Size: 10,
		},
	})
	if err != nil {
		log.Printf("MakeValue Error: %s", err.Error())
		return 0
	}
	return style
}

// 엑셀에 들어가는 각 데이터 제목의 엑셀 스타일 설정
func ColumnStyle(f *excelize.File) int {
	bordersetting := make([]excelize.Border, 0)
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "left",
		Style: 2,
		Color: "#000000",
	})
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "right",
		Style: 2,
		Color: "#000000",
	})
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "top",
		Style: 2,
		Color: "#000000",
	})
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "bottom",
		Style: 2,
		Color: "#000000",
	})
	style, err := f.NewStyle(&excelize.Style{
		Border: bordersetting,
		Alignment: &excelize.Alignment{
			Horizontal: "center",
			Vertical:   "center",
		},
		Font: &excelize.Font{
			Bold: true,
			Size: 10,
		},
		Fill: excelize.Fill{
			Type:    "pattern",
			Pattern: 1,
			Color:   []string{"#b8b8b8"},
		},
	})
	if err != nil {
		log.Printf("MakeColumn Error: %s", err.Error())
		return 0
	}
	return style
}

// 엑셀에 들어가는 머지된 셀에 대한 엑셀 스타일 설정
func MergedTitleStyle(f *excelize.File) int {
	bordersetting := make([]excelize.Border, 0)
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "left",
		Style: 2,
		Color: "#000000",
	})
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "right",
		Style: 2,
		Color: "#000000",
	})
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "top",
		Style: 2,
		Color: "#000000",
	})
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "bottom",
		Style: 2,
		Color: "#000000",
	})
	style, err := f.NewStyle(&excelize.Style{
		Border: bordersetting,
		Alignment: &excelize.Alignment{
			Horizontal: "center",
			Vertical:   "center",
		},
		Font: &excelize.Font{
			Bold: true,
			Size: 10,
		},
		Fill: excelize.Fill{
			Type:    "pattern",
			Pattern: 1,
			Color:   []string{"#b8b8b8"},
		},
	})
	if err != nil {
		log.Printf("MergedTitle Error: %s", err.Error())
		return 0
	}
	return style
}

// 소주제에 대한 엑셀 스타일 설정
func SubtitleStyle(f *excelize.File, rowindex int) (int, int) {
	bordersetting := make([]excelize.Border, 0)
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "left",
		Style: 2,
		Color: "#fcff96",
	})
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "right",
		Style: 2,
		Color: "#fcff96",
	})
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "top",
		Style: 2,
		Color: "#fcff96",
	})
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "bottom",
		Style: 2,
		Color: "#fcff96",
	})
	style, err := f.NewStyle(&excelize.Style{
		Border: bordersetting,
		Alignment: &excelize.Alignment{
			Horizontal: "left",
			Vertical:   "center",
			Indent:     1,
		},
		Font: &excelize.Font{
			Bold: true,
			Size: 10,
		},
		Fill: excelize.Fill{
			Type:    "pattern",
			Pattern: 1,
			Color:   []string{"#fcff96"},
		},
	})
	if err != nil {
		log.Printf("MakeSubtitle Error: %s", err.Error())
		return 0, rowindex + 1
	}
	return style, rowindex
}

func TitleStyle(f *excelize.File) int {
	bordersetting := make([]excelize.Border, 0)
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "left",
		Style: 2,
		Color: "#000000",
	})
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "right",
		Style: 2,
		Color: "#000000",
	})
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "top",
		Style: 2,
		Color: "#000000",
	})
	bordersetting = append(bordersetting, excelize.Border{
		Type:  "bottom",
		Style: 2,
		Color: "#000000",
	})
	style, err := f.NewStyle(&excelize.Style{
		Border: bordersetting,
		Alignment: &excelize.Alignment{
			Horizontal: "center",
			Vertical:   "center",
		},
		Font: &excelize.Font{
			Bold: true,
			Size: 20,
		},
	})
	if err != nil {
		log.Printf("Make Title Error: %s", err.Error())
		return 0
	}
	return style
}

//////////////////////// Type ////////////////////////////////// 코드에 사용될 객체

type Account struct { //코드에서 사용될 각 고객사의 AWS 정보
	AccountID   string     // 고객사 AWS 계정 숫자 ID
	AccountName string     // 고객사의 한국 명칭
	Filename    string     // 각 고객사의 Access Key, Secret Key가 저장된 파일 명
	AwsCfg      aws.Config // 코드에서 사용되는 AWS config 객체
}

type ResultResource struct { // 결과 데이터
	AccountID       string              // 고객사 AWS 계정 숫자 ID
	AccountName     string              // 고객사의 한국 명칭
	EC2             []*EC2Data          //EC2 데이터
	EC2Running      int                 // EC2 동작 여부 데이터
	EC2Stopped      int                 // EC2 동작 여부 데이터
	VPN             []*VPNData          // VPN 데이터
	ClusterData     []*ClusterData      // Aurora Cluster 정보
	RDSData         []*RDSData          // RDS 정보
	LB              []*LoadBalancerData //LB 정보
	TargetGroupData []*TargetGroupData  // Target Group 정보
	EBSData         []*EBSData          // EBS 정보
	EIPData         []*EIPData          // EIP 정보
	S3Data          []*S3Data           // S3 정보
	//LBCount        LBCountData
	NatGatewayData        []*NatGatewayData        // Nat Gateway 정보
	SecurityGroupRuleData []*SecurityGroupRuleData // 보안그룹 정보
	EKSData               []*EKSData               // EKS 정보
	CloudwatchAlarmData   []*AlarmData             // Cloudwatch Alarm 정보
	VPCData               []*VPCData               // VPC 정보
	SubnetData            []*SubnetData            // 서브넷 정보
	CFData                []*CFData                // Cloudfront 정보
}

type CFData struct {
	ID               string
	OriginDomainName string
	Enabled          bool
	DomainName       string
}

type VPCData struct { //VPC 정보
	Id   string // VPC ID
	Name string // 이름
	Cidr string // 16비트 할당된 주소 정보
}

type SubnetData struct { // 서브넷 정보
	VPCId    string // VPC ID
	SubnetId string // 서브넷 ID
	Name     string
	Cidr     string // 서브넷 Cidr
}

type SecurityGroupRuleData struct { // 보안그룹 규칙 정보
	GroupName   string // 보안그룹 명 *API에서 보안그룹 명을 제공하지 않아 데이터를 가져올 수 없음
	GroupID     string // 보안그룹 ID
	RuleID      string // 보안그룹 규칙 ID
	SrcAddr     string // 출발지 주소
	Protocol    string // 프로토콜
	Port        string // 포트 정보
	InOutbound  string // inboud 룰 / outboud 룰 여부
	Description string // 설명
}

type EIPData struct { // EIP 정보
	IPAddress     string // IP 정보
	AssociationId string // 연결 정보
}

type RIData struct { // RI 정보
	RIID           string    // RI ID
	RIStart        time.Time // 시작 시간
	RIEnd          time.Time // 만료 시간
	Platform       string    // 플랫폼 정보
	Tenancy        string
	OfferingClass  string
	OfferingType   string
	RIInstanceType string
	Term           int64 // 기간 1년 또는 3년
	Count          int32 // 수량
}

type EC2Data struct { // EC2 정보
	InstanceName string    // 인스턴스 명
	InstanceId   string    // 인스턴스 ID
	PrivateIP    string    // 사설 IP
	InstanceType string    // 인스턴스 타입
	Usage        string    // 사용 용도
	Hostname     string    // 호스트명
	OSVersion    string    // OS 버전
	Status       string    // 상태
	Site         string    // 사이트
	DBSafer      string    // DB 접근제어 그룹 정보
	RIData       []*RIData // 연결된 RI 정보
}

type VPNData struct { // VPN 정보
	Name string
}

type NatGatewayData struct { // NAT Gateway 정보
	Name string
}

type TargetGroupData struct { // Target Group 정보
	Name      string
	VPCId     string
	Protocol  string   // 프로토콜 정보
	Port      int32    // 포트 정보
	TargetARN string   // 타겟 그룹의 ARN
	LBARN     []string // 타겟그룹이 연결된 LB ARN
	/*
		ListenerRules             []ListenerRule
		TargetIDs                 []string
		HealthCheckProtocol       string
		HealthCheckPort           string
		HealthCheckPath           string
		HealthCheckTimeoutSeconds int32
		HealthCheckThresholdCount int32
		UnhealthyThresholdCount   int32
	*/
}

type ListenerRule struct { // Listener 규칙 정보
	ListenerARN   string
	StickyEnabled bool
	Condition     []Condition
}

type Condition struct {
	Field string
	Value string
}
type LoadBalancerData struct { // LB 정보
	Name       string // LB 이름
	Type       string // Application , Network, Gateway ...
	InExternal string // Internet facing, Internal
	PrdDev     string // 운영, 검증 여부
}

type EBSData struct { // EBS 정보
	ID    string // EBS 볼륨 ID 정보
	Name  string // 볼륨 이름 정보
	Type  string // EBS 타입
	Size  int32  // 사이즈 정보
	IOPS  int32  // IOPS
	State string
}

type LBCountData struct { // LB 집계정보 *현재 엑셀에 표시되지는 않음
	PrdExtAlb int
	PrdExtNlb int
	PrdIntAlb int
	PrdIntNlb int
	DevExtAlb int
	DevExtNlb int
	DevIntAlb int
	DevIntNlb int
}

type ClusterData struct { // Cluster 정보
	Identifier     string    // Cluster ID
	Engine         string    // mysql, postres ...
	EngineVersion  string    // Engine 버전 정보
	Status         string    // cluster 상태
	CName          string    // Cluster 엔드포인트에 할당한 Cname 정보
	EndPoint       string    // Cluster 엔드포인트 정보
	ReaderEndpoint string    // 읽기 엔드포인트 정보
	MultiAZ        bool      // 복수의 가용영역 사용 여부
	Port           string    // 대표 포트
	Usage          string    // 사용 용도
	DBSafer        string    // DBSafer 그룹정보
	RDSData        []RDSData // 클러스터에 속한 노드 정보
}

type RDSData struct {
	Identifier       string       // RDS ID 정보
	Engine           string       // mysql, postgres...
	EngineVersion    string       // Engine 버전 정보
	CName            string       // 노드 엔드포인트에 할당된 Cname 정보
	EndpointAddress  string       // 엔드포인트 정보
	MultiAZ          bool         // 복수의 가용영역 사용 여부
	StorageType      string       // storage 타입 정보
	InstanceClass    string       // 인스턴스 타입 정보
	InstancePort     int32        // 포트 정보
	AllocatedStorage int32        // 할당된 스토리지 정보
	Usage            string       // 사용 용도
	DBSafer          string       // DBSafer 그룹정보
	RDSRIData        []*RDSRIData // RDS RI 정보
}

type RDSRIData struct {
	LeaseId                       string // Lease ID
	DBInstanceClass               string // DB 타입
	DBInstanceCount               int32  // 예약된 숫자
	Term                          int32  // 기간 1년, 3년
	MultiAZ                       bool   // 복수의 가용영역 사용 여부
	OfferingType                  string
	ProductDescription            string
	ReservedDBInstanceId          string    // 예약 인스턴스 ID
	ReservedDBInstancesOfferingId string    // 오퍼링 ID
	StartTime                     time.Time // 시작 시간
	EndTime                       time.Time // 만료 시간
	State                         string    // 활성 상태 여부
}

type S3Data struct { // S3 버킷 정보
	Name        string // 이름
	CreatedDate string // 생성 날짜
}

type EKSData struct { // EKS 정보
	ClusterName   string           // 클러스터 정보
	NodeGroupData []*NodeGroupData // 노드 그룹 정보
}
type NodeGroupData struct { // 노드 그룹 정보
	NodeGroupName string   // 노드그룹 이름
	Version       string   // 노드그룹 클러스터 버전 정보
	InstanceTypes []string // 인스턴스 타입
	DiskSize      int32    // 할당된 디스크 크기
	Min           int32    // 최소 값
	Max           int32    // 최대 값
}

type AlarmData struct { // 클라우드 워치 알람 정보
	Eabled             bool     // 활성화 여부
	Actions            []string // 동작 방식
	Name               string   // 이름
	ComparisonOperator string   // 지표에 대한 비교 연산자
	DatapointsToAlarm  int32    // 경보를 알릴 데이터 포인트
	DimensionName      []string //  지표가 속한 Dimension 이름
	DimensionValue     []string //  지표가 속한 Dimension 값
	EvaluationPeriods  int32    // 알람을 발생시키는 평가 기간
	Period             int32    // 기간
	Statistic          string   // 통계 합계, 최대 등
	Threshold          float64  // 임계값
	TreatMissingData   string   //누락된 데이터 처리
}
