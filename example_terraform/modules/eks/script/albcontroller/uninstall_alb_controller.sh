kubectl delete -f aws-load-balancer-controller-ec2-service-account.yaml
kubectl delete -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
helm uninstall aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system
