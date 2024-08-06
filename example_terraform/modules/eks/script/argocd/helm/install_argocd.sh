kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm search repo argocd
helm install argo argo/argo-cd -f ./values.yaml -n argocd
kubectl port-forward service/argo-argocd-server -n argocd 30080:8080
#kubectl apply -f argocd_ingress.yaml

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
argocd proj create myproject -d https://kubernetes.default.svc,mynamespace -s https://github.com/argoproj/argocd-example-apps.git
