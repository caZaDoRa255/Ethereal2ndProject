resource "aws_iam_role" "bastion_role" {
  name = "BastionHostRole-ott-eks"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "BastionHostRole-ott-eks"
    Environment = "dev"
  }
}

resource "aws_iam_role_policy_attachment" "bastion_ssm_policy_attach" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion_instance_profile" {
  name = "BastionHostInstanceProfile-ott-eks"
  role = aws_iam_role.bastion_role.name
}