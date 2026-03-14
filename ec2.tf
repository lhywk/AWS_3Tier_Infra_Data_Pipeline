resource "aws_launch_template" "template-web" {
  name = var.launch-template-web-name
  image_id = var.image-id # Amazon Linux 2023 등 최신 AMI 확인 필요
  instance_type = var.instance-type

  # IMDSv2 설정: 인스턴스 메타데이터 탈취 공격 방어
  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required" # 토큰 없는 요청 거부 (보안 강화)
    http_put_response_hop_limit = 1 # 외부에서의 비정상 접근 방지
    instance_metadata_tags = "enabled"
  }

  # 네트워크 및 보안 그룹 설정
  network_interfaces {
    device_index = 0
    security_groups = [aws_security_group.asg-sg-web.id]
  }

  # 이전 단계에서 만든 '신분증 케이스' 전달
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm_instance_profile.name
  }

  # 실행 시 WAS ALB의 주소를 주입 (Web -> WAS 통신용)
  user_data = base64encode(templatefile("scripts/web-user-data.sh", {
    alb_dns = "${aws_lb.alb-was.dns_name}"
  }))

  depends_on = [aws_lb.alb-web]

  tag_specifications {
    resource_type = "instance"
    tags = { Name = var.web-instance-name }
  }
}

# 2. WAS 시작 템플릿 선언문
resource "aws_launch_template" "template-was" {
  name = var.launch-template-was-name
  image_id = var.image-id
  instance_type = var.instance-type

  network_interfaces {
    device_index = 0
    security_groups = [aws_security_group.asg-sg-was.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm_instance_profile.name
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags = "enabled"
  }

  # DB 접속 정보를 스크립트에 주입
  user_data = base64encode(templatefile("scripts/app-user-data.sh", {
    host = "${local.host}"
    rds_endpoint = "${aws_db_instance.rds-db.endpoint}" # data 소스 대신 직접 참조 권장
    username = "ho_admin"
    password = "ho_password123!" # 실제 운영시에는 Secret Manager 사용 권장
    db = "hodb"
  }))

  depends_on = [aws_db_instance.rds-db]

  tag_specifications {
    resource_type = "instance"
    tags = { Name = var.was-instance-name }
  }
}

# ASG-Web
resource "aws_autoscaling_group" "asg-web" {
    name = var.asg-sg-web-name
	desired_capacity = 2 # 항상 유지하고 싶은 목표 서버 대수
	max_size = 4 # 트래픽이 폭주할 때 늘어날 수 있는 최대치
	min_size = 2 # 아무리 트래픽이 없어도 유지할 최소치
    target_group_arns = [aws_lb_target_group.tg-web.arn]
    health_check_type = "EC2"
    vpc_zone_identifier = [aws_subnet.web-sub1.id, aws_subnet.web-sub2.id]
    tag {
        key = "asg-web-key"
        value = "asg-web-value"
        propagate_at_launch = true
        # ASG에서 생성된 EC2 인스턴스에 태그를 자동으로 적용할지에 대한 여부 지정
    }
    launch_template {
        id = aws_launch_template.template-web.id
        version = aws_launch_template.template-web.latest_version
    }
    instance_refresh {
        strategy = "Rolling"
        preferences {
            min_healthy_percentage = 50
        }
        triggers = ["tag"]
        # Terraform은 기본적으로 리소스의 설정이 바뀔 때만 변경 작업을 함.
        # 그런데 외부 환경이나 코드 외의 조건에 따라 강제로 실행하고 싶을때가 있음.
        # 이때 triggers를 써서 "이 값이 바뀌면 무조건 다시 실행하라"고 알려줌
    }
}

# ASG-WAS
resource "aws_autoscaling_group" "asg-was" {
    name = var.asg-was-name
    desired_capacity = 2
    max_size = 4
    min_size = 2
    target_group_arns = [aws_lb_target_group.tg-was.arn]
    health_check_type = "EC2"
    vpc_zone_identifier = [aws_subnet.was-sub1.id, aws_subnet.was-sub2.id]
    tag {
        key = "asg-app-key"
        value = "asg-app-value"
        propagate_at_launch = true
        # ASG에서 생성된 EC2 인스턴스에 태그를 자동으로 적용할지에 대한 여부 지정
    }
    launch_template {
        id = aws_launch_template.template-was.id
        version = aws_launch_template.template-was.latest_version
    }
    instance_refresh {
        strategy = "Rolling"
        preferences {
            min_healthy_percentage = 50
        }
        triggers = ["tag"]
    }
}