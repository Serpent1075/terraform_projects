kubectl delete -f istio_ingress.yaml
istioctl uninstall -f istio-operator.yaml
kubectl delete ns istio-system
