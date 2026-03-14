resource "aws_iam_role" "ec2_ssm_role" {
    name = "ho-EC2SSM"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
        }]
    })
}

# IAM 역할 정책 연결
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy_attachment" {
    for_each = toset([
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
    ])
    role = aws_iam_role.ec2_ssm_role.name
    policy_arn = each.key
}
# EC2 인스턴스 프로파일 생성
# EC2 인스턴스를 구분하고 그 인스턴스에 권한을 주기 위한 개념
# 인스턴스 프로파일이 지정된 EC2는 시작 시 역할 정보를 받아오고 해당 역할로 필요한 권한들을 얻게 됨

resource "aws_iam_instance_profile" "ec2_ssm_instance_profile" {
    name = "ho-EC2SSM-Instance-Profile"
    role = aws_iam_role.ec2_ssm_role.name
}