kubectl create namespace istio-system
istioctl install -f istio-operator.yaml
kubectl label namespace default istio-injection=enabled
kubectl apply -f istio_ingress.yaml
