#!/bin/bash

# 기본 설정값
AWS_REGION="ap-northeast-2"
CLUSTER_NAME="ott-eks"
ACCOUNT_ID="979202697408"
ROLE_NAME="BastionHostRole-ott-eks"
PROFILE_NAME="admin"
access_key    = "REPLACE_WITH_YOUR_ACCESS_KEY"
secret_key    = "REPLACE_WITH_YOUR_SECRET_KEY"

# 환경 변수 등록
echo "export AWS_PROFILE=${PROFILE_NAME}" >> /home/ec2-user/.bashrc
echo "export PATH=/home/ec2-user/bin:\$PATH" >> /home/ec2-user/.bashrc
export AWS_PROFILE="${PROFILE_NAME}"
export PATH=/home/ec2-user/bin:$PATH

# 1. bin 디렉토리 생성 및 kubectl 설치
mkdir -p /home/ec2-user/bin
curl -LO "https://dl.k8s.io/release/v1.27.4/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /home/ec2-user/bin/kubectl
chown ec2-user:ec2-user /home/ec2-user/bin/kubectl

# 2. AWS CLI Profile 구성
mkdir -p /home/ec2-user/.aws
cat <<EOF > /home/ec2-user/.aws/credentials
[${PROFILE_NAME}]
aws_access_key_id = ${ACCESS_KEY}
***REMOVED*** = ${SECRET_KEY}
EOF

cat <<EOF > /home/ec2-user/.aws/config
[profile ${PROFILE_NAME}]
region = ${AWS_REGION}
output = json
EOF

chown -R ec2-user:ec2-user /home/ec2-user/.aws

# 3. EKS 클러스터 준비될 때까지 대기
echo "⏳ Waiting for EKS cluster to become ACTIVE..."
until [ "$(aws eks describe-cluster --name ${CLUSTER_NAME} --region ${AWS_REGION} --query 'cluster.status' --output text --profile ${PROFILE_NAME})" == "ACTIVE" ]; do
  echo "🔄 Cluster status is not ACTIVE yet. Waiting 10s..."
  sleep 10
done
echo "✅ Cluster is ACTIVE!"

# 4. kubeconfig 구성
sudo -u ec2-user aws eks update-kubeconfig --region "${AWS_REGION}" --name "${CLUSTER_NAME}" --profile "${PROFILE_NAME}"

# 5. Argo CD 설치
sudo -u ec2-user /home/ec2-user/bin/kubectl create namespace argocd
sudo -u ec2-user /home/ec2-user/bin/kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
sudo -u ec2-user /home/ec2-user/bin/kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
echo "🎉 Argo CD 설치 완료"

# 6. Argo CD App: React 프론트엔드
cat <<EOF > /home/ec2-user/ott-project-app.yml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: frontend
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/caZaDoRa255/AWS2ndProject
    targetRevision: main
    path: ott-project/manifests/k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: frontend
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

sudo -u ec2-user /home/ec2-user/bin/kubectl apply -f /home/ec2-user/ott-project-app.yml -n argocd

# 7. ALB Controller App 배포
cat <<EOF > /home/ec2-user/alb-controller-app.yml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: aws-load-balancer-controller
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://aws.github.io/eks-charts
    targetRevision: 1.13.2
    chart: aws-load-balancer-controller
    helm:
      values: |
        clusterName: ${CLUSTER_NAME}
        serviceAccount:
          create: true
          name: aws-load-balancer-controller
          annotations:
            eks.amazonaws.com/role-arn: "arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
        image:
          repository: 602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon/aws-load-balancer-controller
        region: ${AWS_REGION}
        watchNamespace: ""
  destination:
    server: https://kubernetes.default.svc
    namespace: kube-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

sudo -u ec2-user /home/ec2-user/bin/kubectl apply -f /home/ec2-user/alb-controller-app.yml -n argocd

echo "🎉 AWS Load Balancer Controller Argo CD Application 설치 완료"
