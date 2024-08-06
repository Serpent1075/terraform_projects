export ClusterName=jhoh-tf-fargate-kuber-fargate
export VPCID=vpc-0000123456789
export AccountNum=1234560000
export RegionCode=ap-northeast-2
aws sts get-caller-identity
aws eks --region ${RegionCode} update-kubeconfig --name ${ClusterName}
cat >aws-load-balancer-controller-fargate-service-account.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::${AccountNum}:role/AmazonEKSLoadBalancerControllerFargateRole-${ClusterName}
EOF
kubectl apply -f aws-load-balancer-controller-fargate-service-account.yaml
eksctl create iamidentitymapping \
--cluster ${ClusterName} \
--region=${RegionCode} \
--arn arn:aws:iam::${AccountNum}:role/AmazonEKSLoadBalancerControllerEC2Role-${ClusterName} \
--no-duplicate-arns
#kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
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
