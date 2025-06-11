# irsa.tf (예시 파일명)

# EKS Cluster Data Source (기존 EKS Cluster 정보를 가져오기 위함)
# 이 부분이 없으면 aws_eks_cluster.ott_eks 참조 시 오류 발생.
# ott-eks는 실제 EKS 클러스터 이름과 일치해야 합니다.
data "aws_eks_cluster" "ott_eks" {
  name = var.cluster_name
}

# AWS Caller Identity (계정 ID 가져오기 위함)
data "aws_caller_identity" "current" {}

# 1. IAM Policy for AWS Load Balancer Controller
# iam_policy.json 파일의 내용을 사용합니다.
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy-${var.cluster_name}"
  description = "IAM policy for AWS Load Balancer Controller to manage ALBs"
  policy      = file("iam_policy.json") # iam_policy.json 파일 경로를 지정하세요.
}

# 2. IAM Role for Service Account (IRSA)
resource "aws_iam_role" "alb_controller_irsa_role" {
  name               = "AmazonEKS_AWSLoadBalancerControllerRole-${var.cluster_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # EKS 클러스터의 OIDC Provider ARN을 사용
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.ott_eks.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # OIDC Provider URL과 Service Account 이름이 일치해야 합니다.
            # "kube-system" 네임스페이스와 "aws-load-balancer-controller" Service Account 이름을 사용합니다.
            "${replace(data.aws_eks_cluster.ott_eks.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

# 3. IAM Role Policy Attachment
resource "aws_iam_role_policy_attachment" "alb_controller_policy_attach" {
  policy_arn = aws_iam_policy.alb_controller_policy.arn
  role       = aws_iam_role.alb_controller_irsa_role.name
}

# (선택 사항) cluster_name 변수가 아직 정의되지 않았다면 추가하세요.
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "ott-eks" # 실제 EKS 클러스터 이름으로 변경해주세요.
}