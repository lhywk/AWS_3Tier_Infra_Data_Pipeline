# ALB SG
resource "aws_security_group" "alb-sg-web" { # Web ALB SG
    name = var.alb-sg-web-name
    description = "ALB Security Group"
    vpc_id = aws_vpc.vpc.id
    ingress {
        description = "HTTP from Web Tier"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress { 
        description = "HTTPS from web Tier"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = var.alb-sg-web-name
    }
}

resource "aws_security_group" "alb-sg-was" { # Was ALB SG
    name = var.alb-sg-was-name
    description = "ALB Security Group"
    vpc_id = aws_vpc.vpc.id
    ingress {
        description = "HTTP from Internet"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.asg-sg-web.id]
        # asg-security-group-web이라는 SG에 속한 인스턴스만이 이 포트를 통해 ALB에 접근할수 있도록 제한
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = var.alb-sg-was-name
    }
}

# ASG-Web-SG
resource "aws_security_group" "asg-sg-web" {
    name = var.asg-sg-web-name
    description = "ASG Security Group"
    vpc_id = aws_vpc.vpc.id
    ingress {
        description = "HTTP from ALB"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.alb-sg-web.id]
    }
    ingress {
        description = "SSH From Anywhere or Your-IP"
        # 원격으로 서버 접속해 SW 업데이트, 구성 변경 등
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = var.asg-sg-web-name
    }
}

# ASG-WAS-SG
resource "aws_security_group" "asg-sg-was" {
    name = "ho-asg-sg-was"
    description = "ASG Security Group"
    vpc_id = aws_vpc.vpc.id
    ingress {
        description = "HTTP from ALB"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.alb-sg-was.id]
    }
    ingress {
        description = "SSH from Web Tier"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        # Web 서버 보안 그룹을 가진 인스턴스만 WAS로 SSH 접속 가능하도록 제한
        security_groups = [aws_security_group.asg-sg-web.id]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = var.asg-sg-was-name
    }
}

# DB-SG
resource "aws_security_group" "db-sg" {
    name = var.db-sg-name
    description = "DB Security Group"
    vpc_id = aws_vpc.vpc.id
    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.asg-sg-was.id]
    }
    egress { 
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "ho-db-sg"
    }
}