# DB-Subnet-Group
resource "aws_db_subnet_group" "db-sub-grp" {
    name = var.db-sub-grp-name
    subnet_ids = [aws_subnet.db-sub1.id, aws_subnet.db-sub2.id]
    tags = {
        Name = var.db-sub-grp-name
    }
}

# RDS 파라미터 그룹
resource "aws_db_parameter_group" "mk-par-grp" {
    name = "ho-par-grp"
    family = "mysql8.0"
    description = "Example parameter group for mysql8.0"
    parameter {
        name = "character_set_server"
        value = "utf8mb4"
    }
    # MySQL 서버의 기본 문자셋을 utf8mb4로 설정
    # (4바이트 UTF-8: 이모지 등도 저장 가능)
    parameter {
        name = "collation_server"
        value = "utf8mb4_unicode_ci"
        # 기본 collation (문자 정렬 방식)을 utf8mb4_unicode_ci로 설정
        # (문자 비교시 대소문자 구분 없이 유니코드 기준으로 정렬)
    }
}

# RDS
data "aws_db_instance" "my_rds" {
    db_instance_identifier = aws_db_instance.rds-db.identifier
}

resource "aws_db_instance" "rds-db" {
    allocated_storage = 20
    db_name = var.db-name
    engine = "mysql"
    engine_version = "8.0"
    storage_type = "gp3" // General Purpose SSD (gp3)
    instance_class = var.alb-sg-web-name
    username = var.db-username
    password = var.db-password
    parameter_group_name = aws_db_parameter_group.mk-par-grp.name
    multi_az = false
    db_subnet_group_name = aws_db_subnet_group.db-sub-grp.name
    vpc_security_group_ids = [aws_security_group.db-sg.id]
    skip_final_snapshot = true
    identifier = "ho-rds-instance" // RDS 인스턴스의 이름 지정
}

locals {
  host = replace(aws_db_instance.rds-db.endpoint, ":3306", "")
}
