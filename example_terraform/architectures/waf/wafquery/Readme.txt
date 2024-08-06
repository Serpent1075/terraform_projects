access_key : terraform analyzer를 통해 AWS WAF 로그 분석을 진행한 아테타 쿼리 결과 ID를 저장한 파일을 s3로부터 가져오기 위한 권한, Athena 결과를 읽고 가져올 수 있는 권한 등이 필요
client_list : 위 access_key의 계정에 대한 정보
output: 프로그램이 출력할 결과물
build.bat : main.go 빌드 명령어
main.go: 소스코드
go.mod: 소스에 사용된 패키지 정보
go.sum: 소스에 사용된 패키지 해시코드
wafqueryresult.exe 빌드 결과물