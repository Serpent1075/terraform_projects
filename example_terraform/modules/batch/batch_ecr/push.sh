go build -o myapp main.go
sudo docker build . -t batch-image:2.0
sudo docker tag batch-image:2.0 708595888134.dkr.ecr.ap-northeast-2.amazonaws.com/jhoh-tf-container-registry:latest
sudo docker push 708595888134.dkr.ecr.ap-northeast-2.amazonaws.com/jhoh-tf-container-registry:latest
