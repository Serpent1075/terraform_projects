#  ver.4 2020-03-04   #
#  Add : Targetgroup  #
#  runtime:python3.8  #
#---------------------#


import json
import logging
import os
import datetime

from datetime import  timedelta
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError


# The Slack channel to send a message to stored in the slackChannel environment variable
SLACK_CHANNEL = os.environ['slackChannel']
CLIENT_NAME = os.environ['clientName']
HOOK_URL = "https://hooks.slack.com/services/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"

logger = logging.getLogger()
logger.setLevel(logging.INFO)

Color_Red = "#eb2121"
Color_Green = "#2cc73b"
Color_Sky = "#28a0ff"
Color_Orange = "#FF7F50"


def lambda_handler(event, context):

    
    message = json.loads(event['Records'][0]['Sns']['Message'])
    print (message)

    
    
    if message.get("AlarmName") :
        slack_message = wafalarmevent(message)
        

        
    #print (slack_message)

    req = Request(HOOK_URL, json.dumps(slack_message).encode('utf-8'))
    try:
        response = urlopen(req)
        response.read()
        logger.info("Message posted to %s", slack_message['channel'])
    except HTTPError as e:
        logger.error("Request failed: %d %s", e.code, e.reason)
    except URLError as e:
        logger.error("Server connection failed: %s", e.reason)
        
        
    
    
def wafalarmevent(message):
    alarm_name = message['AlarmName']
    account_id = message['AWSAccountId']
    new_state = message['NewStateValue']
    metricname = message['Trigger']['MetricName']
    
    #time UTC -> UTC+9(KST)
    strtime = message['StateChangeTime'].split(".")
    print("strtime : %s",)
    date = datetime.datetime.strptime(strtime[0],"%Y-%m-%dT%H:%M:%S")
    KST_time =date+timedelta(hours=+9)
    
    #print(KST_time)

    #state color
    if new_state == "INSUFFICIENT_DATA" :
        statecolor = Color_Green
    
    else :
        statecolor = Color_Red
    

    slack_message = {
        'icon_url':'https://sohee-test-s3.s3.ap-northeast-2.amazonaws.com/aws-logo-icon.png',
        'username': 'CloudWatch',
        'channel': SLACK_CHANNEL,
        'attachments':[
            {
                'color': statecolor,
                'attachment_type': "default",
                "title_link": "",
                'text': " AccountID: %s \n ClientName: %s \n AlarmName : %s \n MetricName : %s \n Occuerd Time : %s (KST) " % (account_id,CLIENT_NAME,alarm_name,metricname,KST_time)
            }
        ]
    } 
    
    return (slack_message)

