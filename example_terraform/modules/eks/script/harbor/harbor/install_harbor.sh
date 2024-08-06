helm repo add harbor https://helm.goharbor.io
#helm fetch harbor/harbor --untar
kubectl create ns harbor
#helm install harbor harbor/harbor-registry -f values.yaml -n harbor
helm install harbor -f values.yaml . -n harbor
