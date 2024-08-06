helm list -n harbor
helm uninstall harbor -n harbor
kubectl delete namespaces harbor
