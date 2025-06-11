variable "db_password" {
  description = "Password for RDS database"
  type        = string
  sensitive   = true
}

variable "key_pair_name" {
  description = "SSH key pair name for EC2 access"
  type        = string
}

variable "my_ip" {
  description = "Your public IP address to access the bastion host"
  type        = string
}

variable "aws_region" {
  description = "AWS region for the resources"
  type        = string
  default     = "ap-northeast-2" # 당신의 AWS 리전 기본값
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "ott-eks" # 당신의 EKS 클러스터 이름 기본값
}

variable "secret_key" {
  type = string
}
variable "access_key" {
  type = string
}