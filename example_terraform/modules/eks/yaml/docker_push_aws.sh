version="4.0"
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin 088755231083.dkr.ecr.ap-northeast-2.amazonaws.com
docker build -t whitewhale:$version .
docker tag whitewhale:$version 088755231083.dkr.ecr.ap-northeast-2.amazonaws.com/whitewhale:$version
docker push 088755231083.dkr.ecr.ap-northeast-2.amazonaws.com/whitewhale:$version
