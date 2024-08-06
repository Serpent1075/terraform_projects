go env -w GOOS=linux
go build -tags lambda.norpc -o bootstrap main.go
build-lambda-zip.exe -o analyzer.zip .\bootstrap
go env -w GOOS=windows