kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
#kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/ha/install.yaml

#https://argo-cd.readthedocs.io/en/stable/cli_installation/
#helm repo add argo https://argoproj.github.io/argo-helm
#curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
#sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
#rm argocd-linux-amd64
#kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
kubectl apply -f argocd_ingress.yaml
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

argocd proj create myproject -d https://kubernetes.default.svc,mynamespace -s https://github.com/argoproj/argocd-example-apps.git
