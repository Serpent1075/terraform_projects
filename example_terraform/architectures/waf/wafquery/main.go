package main

import (
	"context"
	"encoding/csv"
	"io"
	"log"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/athena"
	"github.com/aws/aws-sdk-go-v2/service/athena/types"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/wafv2"
	"github.com/xuri/excelize/v2"
)

func main() {
	accountlist := ReadAccount()
	accountlist = ReadAccessKey(context.Background(), accountlist)
	for _, data := range accountlist {
		managedrulegroups, customrulegroups := GetWafACLState(data)
		GetAthenaQueryIDFromS3(data)
		GetQueryAndExcelize(data, managedrulegroups, customrulegroups)
	}
}

func GetWafACLState(account *Account) ([]*ManagedWAFRule, []*CustomRule) {
	wafclient := wafv2.NewFromConfig(account.AwsCfg)
	wafaclinput := wafv2.ListWebACLsInput{
		Limit: aws.Int32(20),
		Scope: "REGIONAL",
	}
	wafacloutput, wafacloutputerr := wafclient.ListWebACLs(context.Background(), &wafaclinput)
	var curmanagedrulegroup []*ManagedWAFRule = make([]*ManagedWAFRule, 0)
	var curcustomrulegroup []*CustomRule = make([]*CustomRule, 0)
	check(wafacloutputerr)
	for _, data := range wafacloutput.WebACLs {
		if len(*data.Name) != 0 {
			getwebaclinput := wafv2.GetWebACLInput{
				Id:    data.Id,
				Name:  data.Name,
				Scope: "REGIONAL",
			}
			webacloutput, webacloutputerr := wafclient.GetWebACL(context.Background(), &getwebaclinput)
			check(webacloutputerr)

			for _, rule := range webacloutput.WebACL.Rules {
				if strings.Contains(*rule.Name, "Managed") {
					describemanagedruleinput := wafv2.DescribeManagedRuleGroupInput{
						Name:       rule.Name,
						VendorName: aws.String("AWS"),
						Scope:      "REGIONAL",
					}
					describemanagedruleoutput, describemanagedruleoutputerr := wafclient.DescribeManagedRuleGroup(context.Background(), &describemanagedruleinput)
					check(describemanagedruleoutputerr)

					for _, managedrulegroup := range describemanagedruleoutput.Rules {
						var action string

						if managedrulegroup.Action != nil {
							if managedrulegroup.Action.Allow != nil {
								if rule.OverrideAction != nil && rule.OverrideAction.Count != nil {
									action = "Count"
								} else {
									action = "Allow"
								}
							} else if managedrulegroup.Action.Block != nil {
								if rule.OverrideAction != nil && rule.OverrideAction.Count != nil {
									action = "Count"
								} else {
									action = "Block"
								}
							} else if managedrulegroup.Action.Captcha != nil {
								if rule.OverrideAction != nil && rule.OverrideAction.Count != nil {
									action = "Count"
								} else {
									action = "Captcha"
								}
							} else if managedrulegroup.Action.Challenge != nil {
								if rule.OverrideAction != nil && rule.OverrideAction.Count != nil {
									action = "Count"
								} else {
									action = "Challenge"
								}
							} else if managedrulegroup.Action.Count != nil {
								if rule.OverrideAction != nil && rule.OverrideAction.Count != nil {
									action = "Count"
								} else {
									action = "Count"
								}
							}
						} else {
							action = ""
						}
						managedrule := ManagedWAFRule{
							RuleGroupName: *rule.Name,
							RuleName:      *managedrulegroup.Name,
							Action:        action,
						}
						curmanagedrulegroup = append(curmanagedrulegroup, &managedrule)

					}
				} else {
					listrulegroupinput := wafv2.ListRuleGroupsInput{
						Scope: "REGIONAL",
					}

					listrulegroupoutput, listrulegroupoutputerr := wafclient.ListRuleGroups(context.Background(), &listrulegroupinput)
					check(listrulegroupoutputerr)
					for _, rulegroup := range listrulegroupoutput.RuleGroups {
						getrulgroupinput := wafv2.GetRuleGroupInput{
							Name:  rulegroup.Name,
							Id:    rulegroup.Id,
							Scope: "REGIONAL",
						}
						getrulegroupoutput, getrulegroupoutputerr := wafclient.GetRuleGroup(context.Background(), &getrulgroupinput)
						check(getrulegroupoutputerr)
						for _, customrule := range getrulegroupoutput.RuleGroup.Rules {
							var action string
							if customrule.Action != nil {
								if customrule.Action.Allow != nil {
									if rule.OverrideAction != nil && rule.OverrideAction.Count != nil {
										action = "Count"
									} else {
										action = "Allow"
									}
								} else if customrule.Action.Block != nil {
									if rule.OverrideAction != nil && rule.OverrideAction.Count != nil {
										action = "Count"
									} else {
										action = "Block"
									}
								} else if customrule.Action.Captcha != nil {
									if rule.OverrideAction != nil && rule.OverrideAction.Count != nil {
										action = "Count"
									} else {
										action = "Captcha"
									}
								} else if customrule.Action.Challenge != nil {
									if rule.OverrideAction != nil && rule.OverrideAction.Count != nil {
										action = "Count"
									} else {
										action = "Challenge"
									}
								} else if customrule.Action.Count != nil {
									if rule.OverrideAction != nil && rule.OverrideAction.Count != nil {
										action = "Count"
									} else {
										action = "Count"
									}
								}
							} else {
								action = ""
							}
							customrule := CustomRule{
								RuleGroupName: *rule.Name,
								RuleName:      *customrule.Name,
								Action:        action,
							}
							curcustomrulegroup = append(curcustomrulegroup, &customrule)
						}

					}

				}
			}
		}
	}
	return curmanagedrulegroup, curcustomrulegroup
}

type CustomRule struct {
	RuleGroupName string
	RuleName      string
	Action        string
}

type ManagedWAFRule struct {
	RuleGroupName string
	RuleName      string
	Action        string
}

func GetQueryAndExcelize(account *Account, managedrulegroups []*ManagedWAFRule, customrulegroups []*CustomRule) {
	athenaclient := athena.NewFromConfig(account.AwsCfg)

	f := excelize.NewFile(excelize.Options{})
	f.SetSheetName("Sheet1", "Default")

	defer func() {
		if err := f.Close(); err != nil {
			log.Printf("MakeExcelReport Error: %s", err.Error())
		}
	}()

	RuleGroupExcelize(f, managedrulegroups, customrulegroups)

	GetQueryResultAndExcelize(athenaclient, f, account.AthenaQueryID.RuleAllowQueryID, "RuleAllow")

	GetQueryResultAndExcelize(athenaclient, f, account.AthenaQueryID.RuleBlockQueryID, "RuleBlock")

	GetQueryResultAndExcelize(athenaclient, f, account.AthenaQueryID.RuleAllInboundQueryID, "RuleAllInbound")

	GetQueryResultAndExcelize(athenaclient, f, account.AthenaQueryID.GetAllowedUrlCountQueryID, "AllowedUrlCount")

	GetQueryResultAndExcelize(athenaclient, f, account.AthenaQueryID.GetBlockedUrlCountQueryID, "BlockedUrlCount")

	GetQueryResultAndExcelize(athenaclient, f, account.AthenaQueryID.GetAllowedPathCountQueryID, "AllowedPathCount")

	GetQueryResultAndExcelize(athenaclient, f, account.AthenaQueryID.GetBlockedPathCountQueryID, "BlockedPathCount")

	GetQueryResultAndExcelize(athenaclient, f, account.AthenaQueryID.GetAllowedUrlAndPathDetailQueryID, "AllowedUrlAndPathDetail")

	GetQueryResultAndExcelize(athenaclient, f, account.AthenaQueryID.GetBlockedUrlAndPathDetailQueryID, "BlockedUrlAndPathDetail")

	GetQueryResultAndExcelize(athenaclient, f, account.AthenaQueryID.CountryQueryID, "CountryQueryID")

	f.SetActiveSheet(0)
	// 지정 된 경로를 기반으로 파일 저장
	f.DeleteSheet("Default")
	filename := account.AccountName + "_" + getDateString(time.Now().Year()) + "_" + getDateString(int(time.Now().Month())) + getDateString(time.Now().Day()) + ".xlsx"
	if err := f.SaveAs("./output/" + filename); err != nil {
		log.Printf("MakeExcelReport Error: %s", err.Error())
	}
}

func RuleGroupExcelize(f *excelize.File, managedrule []*ManagedWAFRule, customrule []*CustomRule) {
	_, managederr := f.NewSheet("Managed Rule")
	if managederr != nil {
		log.Printf("MakeExcelReport Error: %s", managederr.Error())
		return
	}
	var rowindex int = 2

	style := ColumnStyle(f)
	f.SetCellStyle("Managed Rule", "A"+strconv.Itoa(rowindex), "C"+strconv.Itoa(rowindex), style)
	f.SetCellValue("Managed Rule", "A"+strconv.Itoa(rowindex), "Rule Group Name")
	f.SetCellValue("Managed Rule", "B"+strconv.Itoa(rowindex), "Rule Name")
	f.SetCellValue("Managed Rule", "C"+strconv.Itoa(rowindex), "Action")
	rowindex++
	for _, data := range managedrule {
		style = ValueStyle(f)
		f.SetCellStyle("Managed Rule", "A"+strconv.Itoa(rowindex), "C"+strconv.Itoa(rowindex), style)
		f.SetCellValue("Managed Rule", "A"+strconv.Itoa(rowindex), data.RuleGroupName)
		f.SetCellValue("Managed Rule", "B"+strconv.Itoa(rowindex), data.RuleName)
		f.SetCellValue("Managed Rule", "C"+strconv.Itoa(rowindex), data.Action)
		rowindex++
	}

	_, customerr := f.NewSheet("Custom Rule")
	if customerr != nil {
		log.Printf("MakeExcelReport Error: %s", customerr.Error())
		return
	}

	rowindex = 2

	style = ColumnStyle(f)
	f.SetCellStyle("Custom Rule", "A"+strconv.Itoa(rowindex), "C"+strconv.Itoa(rowindex), style)
	f.SetCellValue("Custom Rule", "A"+strconv.Itoa(rowindex), "Rule Group Name")
	f.SetCellValue("Custom Rule", "B"+strconv.Itoa(rowindex), "Rule Name")
	f.SetCellValue("Custom Rule", "C"+strconv.Itoa(rowindex), "Action")
	rowindex++
	for _, data := range customrule {
		style = ValueStyle(f)
		f.SetCellStyle("Custom Rule", "A"+strconv.Itoa(rowindex), "C"+strconv.Itoa(rowindex), style)
		f.SetCellValue("Custom Rule", "A"+strconv.Itoa(rowindex), data.RuleGroupName)
		f.SetCellValue("Custom Rule", "B"+strconv.Itoa(rowindex), data.RuleName)
		f.SetCellValue("Custom Rule", "C"+strconv.Itoa(rowindex), data.Action)
		rowindex++
	}
}

func GetQueryResultAndExcelize(athenaclient *athena.Client, f *excelize.File, queryExecutionId string, queryExecutionTitle string) {
	athenainput := athena.GetQueryResultsInput{
		QueryExecutionId: aws.String(queryExecutionId),
	}

	athenaoutput, athenaoutputerr := athenaclient.GetQueryResults(context.Background(), &athenainput)
	check(athenaoutputerr)
	_, err := f.NewSheet(queryExecutionTitle)
	if err != nil {
		log.Printf("MakeExcelReport Error: %s", err.Error())
		return
	}

	var rowindex int = 0
	var style int = 0
	for i, row := range athenaoutput.ResultSet.Rows {
		if i == 0 {
			style = ColumnStyle(f)
		} else {
			style = ValueStyle(f)
		}

		rowindex = RuleAllowQueryIDExcelize(f, queryExecutionTitle, rowindex, row, style)
	}
}

func RuleAllowQueryIDExcelize(f *excelize.File, title string, rowindex int, row types.Row, style int) int {
	f.SetCellStyle(title, "A"+strconv.Itoa(2), string(toChar(len(row.Data)))+strconv.Itoa(rowindex+1), style)
	for i, data := range row.Data {
		var valuedata string
		if data.VarCharValue != nil {
			valuedata = *data.VarCharValue
		} else {
			valuedata = ""
		}
		f.SetCellValue(title, string(toChar(i+1))+strconv.Itoa(rowindex+1), valuedata)
	}

	return rowindex + 1
}

func GetAthenaQueryIDFromS3(account *Account) {
	bucket := "aws-waf-logs-" + account.Prefix

	key := "output/waflog_query_state/waflog_query_id_" + strconv.Itoa(time.Now().Year()) + "_" + getDateString(int(time.Now().Month())-1) + ".csv"

	s3client := s3.NewFromConfig(account.AwsCfg)
	s3input := s3.GetObjectInput{
		Bucket:              aws.String(bucket),
		Key:                 aws.String(key),
		ExpectedBucketOwner: aws.String(account.AccountID),
	}

	output, outputerr := s3client.GetObject(context.Background(), &s3input)
	check(outputerr)
	data, readcsverr := ReadCsv(output.Body)
	check(readcsverr)

	account.AthenaQueryID.RuleAllowQueryID = data[1][0]
	account.AthenaQueryID.RuleBlockQueryID = data[1][1]
	account.AthenaQueryID.RuleAllInboundQueryID = data[1][2]
	account.AthenaQueryID.GetAllowedUrlCountQueryID = data[1][3]
	account.AthenaQueryID.GetBlockedUrlCountQueryID = data[1][4]
	account.AthenaQueryID.GetAllowedPathCountQueryID = data[1][5]
	account.AthenaQueryID.GetBlockedPathCountQueryID = data[1][6]
	account.AthenaQueryID.GetAllowedUrlAndPathDetailQueryID = data[1][7]
	account.AthenaQueryID.GetBlockedUrlAndPathDetailQueryID = data[1][8]
	account.AthenaQueryID.CountryQueryID = data[1][9]
}

//GetAllowedUrlCountQueryID         string `csv:"GetAllowedUrlCountQueryID"`
//GetBlockedUrlCountQueryID         string `csv:"GetBlockedUrlCountQueryID"`
//GetAllowedPathCountQueryID        string `csv:"GetAllowedPathCountQueryID"`
//GetBlockedPathCountQueryID        string `csv:"GetBlockedPathCountQueryID"`
//GetAllowedUrlAndPathDetailQueryID string `csv:"GetAllowedUrlAndPathDetailQueryID"`
//GetBlockedUrlAndPathDetailQueryID string `csv:"GetBlockedUrlAndPathDetailQueryID"`

func ReadAccessKey(ctx context.Context, accountids []*Account) []*Account {
	for i, account := range accountids {

		file, _ := os.Open("./access_key/" + strings.TrimSpace(account.Filename))
		keydata, err := ReadCsv(file)
		check(err)

		cfg, err := config.LoadDefaultConfig(
			context.TODO(),
			config.WithCredentialsProvider(
				credentials.NewStaticCredentialsProvider(keydata[1][0], keydata[1][1], ""),
			),
		)
		check(err)
		accountids[i].AwsCfg = cfg
	}
	return accountids
}

func ReadAccount() []*Account {
	file, _ := os.Open("./client_list/client.csv")
	clientdatas, err := ReadCsv(file)
	check(err)
	var accountlist []*Account = make([]*Account, 0)
	for i, data := range clientdatas {
		if i != 0 {
			accountdata := Account{
				AccountID:   data[0],
				AccountName: data[1],
				Filename:    data[2],
				Prefix:      data[3],
			}
			accountlist = append(accountlist, &accountdata)
		}
	}
	return accountlist
}

func getDateString(date int) string {
	if date < 10 {
		return "0" + strconv.Itoa(date)
	} else {
		return strconv.Itoa(date)
	}
}

func toChar(i int) rune {
	return rune('A' - 1 + i)
}

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

type AthenaQueryID struct {
	RuleAllowQueryID                  string `csv:"RuleAllowQueryID"`
	RuleBlockQueryID                  string `csv:"RuleBlockQueryID"`
	RuleAllInboundQueryID             string `csv:"RuleAllInboundQueryID"`
	GetAllowedUrlCountQueryID         string `csv:"GetAllowedUrlCountQueryID"`
	GetBlockedUrlCountQueryID         string `csv:"GetBlockedUrlCountQueryID"`
	GetAllowedPathCountQueryID        string `csv:"GetAllowedPathCountQueryID"`
	GetBlockedPathCountQueryID        string `csv:"GetBlockedPathCountQueryID"`
	GetAllowedUrlAndPathDetailQueryID string `csv:"GetAllowedUrlAndPathDetailQueryID"`
	GetBlockedUrlAndPathDetailQueryID string `csv:"GetBlockedUrlAndPathDetailQueryID"`
	CountryQueryID                    string `csv:"CountryQueryID"`
}

type Account struct {
	AccountID     string
	AccountName   string
	Filename      string
	AwsCfg        aws.Config
	Prefix        string
	AthenaQueryID AthenaQueryID
}
