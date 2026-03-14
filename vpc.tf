resource "aws_vpc" "vpc" {
    cidr_block = var.vpc-cidr
    enable_dns_support = true
    # Amazon의 DNS 서버가 VPC 내부에서 DNS 쿼리를 해석할 수 있도록 함
    enable_dns_hostnames = true
    # VPC에서 인스턴스에 대해 DNS 호스트 이름을 할당할 수 있는지 여부를 결정
    tags = {
        Name = var.vpc-name
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id # igw를 해당 vpc에 attach
    tags = {
        Name = var.igw-name
    }
}

resource "aws_eip" "eip1" {
    domain = "vpc" # 해당 EIP가 VPC 내에서만 사용 가능하도록 설정
}

resource "aws_eip" "eip2" {
    domain = "vpc"
}

resource "aws_nat_gateway" "nat-gw1" {
    allocation_id = aws_eip.eip1.id # EIP 할당
    connectivity_type = "public"
    subnet_id = aws_subnet.pub-sub1.id # NATGW를 생성할 서브넷
    tags = {
        Name = var.nat-gw1-name
    }
    depends_on = [aws_internet_gateway.igw]
    # 리소스 간 생성 순서 보장(IGW 생성 후 NATGW 생성)
}

resource "aws_nat_gateway" "nat-gw2" {
    allocation_id = aws_eip.eip2.id # EIP 할당
    connectivity_type = "public"
    subnet_id = aws_subnet.pub-sub2.id # NATGW를 생성할 서브넷
    tags = {
        Name = var.nat-gw2-name
    }
    depends_on = [aws_internet_gateway.igw]
    # 리소스 간 생성 순서 보장(IGW 생성 후 NATGW 생성)
}

# Public Subnet, Pbulic Rounting Table
resource "aws_subnet" "pub-sub1" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.pub-sub1-cidr
    availability_zone = var.az-a
    map_public_ip_on_launch = true # 퍼블릭 IP 주소 자동 할당
    tags = {
        Name = var.pub-sub1-name
    }
}

resource "aws_subnet" "pub-sub2" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.pub-sub2-cidr
    availability_zone = var.az-c
    map_public_ip_on_launch = true
    tags = {
        Name = var.pub-sub2-name
    }
}

resource "aws_route_table" "pub-rt" {
    vpc_id = aws_vpc.vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id # 모든 트래픽은 IGW로 
    }
    tags = {
        Name = var.pub-rt-name
    }
}

resource "aws_route_table_association" "pub-rt-asso1" {
    # public subnet들을 public rt에 연결
    subnet_id = aws_subnet.pub-sub1.id
    route_table_id = aws_route_table.pub-rt.id
}

resource "aws_route_table_association" "pub-rt-asso2" {
    subnet_id = aws_subnet.pub-sub2.id
    route_table_id = aws_route_table.pub-rt.id
}

# Private Subnet, Private Routing Table
resource "aws_subnet" "web-sub1" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.web-sub1-cidr
    availability_zone = var.az-a
    map_public_ip_on_launch = false
    tags = {
        Name = var.web-sub1-name
    }
}

resource "aws_subnet" "web-sub2" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.web-sub2-cidr
    availability_zone = var.az-c
    map_public_ip_on_launch = false
    tags = {
        Name = var.web-sub2-name
    }
}

resource "aws_subnet" "was-sub1" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.was-sub1-cidr
    availability_zone = var.az-a
    map_public_ip_on_launch = false
    tags = {
        Name = var.was-sub1-name
    }
}

resource "aws_subnet" "was-sub2" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.was-sub2-cidr
    availability_zone = var.az-c
    map_public_ip_on_launch = false
    tags = {
        Name = var.was-sub2-name
    }
}

resource "aws_subnet" "db-sub1" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.db-sub1-cidr
    availability_zone = var.az-a
    map_public_ip_on_launch = false
    tags = {
        Name = var.db-sub1-name
    }
}

resource "aws_subnet" "db-sub2" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.db-sub2-cidr
    availability_zone = var.az-c
    map_public_ip_on_launch = false
    tags = {
        Name = var.db-sub2-name
    }
}

resource "aws_route_table" "pri-rt1" {
    vpc_id = aws_vpc.vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.nat-gw1.id
    }
    tags = {
        Name = var.pri-rt1-name
    }
}

resource "aws_route_table" "pri-rt2" {
    vpc_id = aws_vpc.vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.nat-gw2.id
    }
    tags = {
        Name = var.pri-rt2-name
    }
}

# WEB
resource "aws_route_table_association" "pri-rt-asso1" { 
    subnet_id = aws_subnet.web-sub1.id
    route_table_id = aws_route_table.pri-rt1.id
}

resource "aws_route_table_association" "pri-rt-asso2" {
    subnet_id = aws_subnet.web-sub2.id
    route_table_id = aws_route_table.pri-rt2.id
}

# WAS
resource "aws_route_table_association" "pri-rt-asso3" {
    subnet_id = aws_subnet.was-sub1.id
    route_table_id = aws_route_table.pri-rt1.id
}

resource "aws_route_table_association" "pri-rt-asso4" {
    subnet_id = aws_subnet.was-sub2.id
    route_table_id = aws_route_table.pri-rt2.id
}

# DB
resource "aws_route_table_association" "pri-rt-asso5" {
    subnet_id = aws_subnet.db-sub1.id
    route_table_id = aws_route_table.pri-rt1.id
}
resource "aws_route_table_association" "pri-rt-asso6" {
    subnet_id = aws_subnet.db-sub2.id
    route_table_id = aws_route_table.pri-rt2.id
}