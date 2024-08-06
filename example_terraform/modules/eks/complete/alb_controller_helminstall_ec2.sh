export ClusterName=jhoh-tf-ec2-kuber
export VPCID=vpc-0491de6beeb82d772
export AccountNum=088755231083
export RegionCode=ap-northeast-2
aws sts get-caller-identity
aws eks --region ${RegionCode} update-kubeconfig --name ${ClusterName}
#kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
cat >aws-load-balancer-controller-ec2-service-account.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::${AccountNum}:role/AmazonEKSLoadBalancerControllerEC2Role-${ClusterName}
EOF
kubectl apply -f aws-load-balancer-controller-ec2-service-account.yaml
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
eksctl create iamidentitymapping \
--cluster ${ClusterName} \
--region=${RegionCode} \
--arn arn:aws:iam::${AccountNum}:role/AmazonEKSLoadBalancerControllerEC2Role-${ClusterName} \
--no-duplicate-arns
eksctl create iamserviceaccount --name external-dns --namespace default --cluster ${ClusterName} --attach-policy-arn arn:aws:iam::708595888134:policy/jhoh-tf-external-dns-policy --approve
kubectl apply -f external_dns_manifest.yaml
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm search repo eks
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
-n kube-system \
--set clusterName=${ClusterName} \
--set serviceAccount.create=false \
--set serviceAccount.name=aws-load-balancer-controller \
--set image.repository=602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon/aws-load-balancer-controller \
--set region=${RegionCode} \
--set vpcid=${VPCID}
#curl -L https://git.io/get_helm.sh | bash -s -- --version v3.8.2
