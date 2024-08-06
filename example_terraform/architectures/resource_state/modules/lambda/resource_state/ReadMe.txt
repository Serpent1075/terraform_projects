go env -w GOOS=linux
go env -w GOARCH=amd64
go build -o resource_state main.go

######
go 언어로 작성된 코드를 그대로 lambda에 넣을 경우, entrypoint를 못찾는 에러가 발생

https://github.com/aws/aws-lambda-go/blob/main/cmd/build-lambda-zip/main.go
해당 사이트에서 main.go를 받아 build를 한 후 결과물을 cmd에서 사용할 수 있도록 환경변수에 등록합니다. (go build -o build-lambda-zip.exe main.go)
또는, 함께 업로드한 build-lambda-zip를 사용하여 환경변수에 등록해도 됩니다. (windows 환경에서만 사용가능하며 linux환경에서 빌드할 경우 go env -w GOOS=linux를 터미널에 입력한 후 사용하시길 바랍니다.)

https://docs.aws.amazon.com/ko_kr/lambda/latest/dg/golang-package.html#golang-package-windows
환경변수에 등록됬으면 다음 링크를 참고하여 제시된 방법대로 build를 진행한 후 람다에 업로드 합니다.

몇 번 테스트를 진행해보았지만 테라폼코드에서 go언어로 작성된 코드를 위 방법으로 빌드 및 압축하여 테라폼 코드로 바로 적용을 해보려고 하였지만, 파일을 못 찾는 이슈가 있어
업로드 시 수동으로 zip파일을 람다 함수에 적용이 필요합니다.