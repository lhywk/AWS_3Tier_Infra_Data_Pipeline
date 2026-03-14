#!/bin/bash
# Amazon Linux 2 userdata script for setting up Nginx with ProxyPass

# 1. 시스템 업데이트 및 필수 패키지 설치
sudo yum update -y
sudo yum install -y nginx amazon-ssm-agent

# 2. 서비스 시작 및 자동 실행 설정
sudo systemctl start nginx amazon-ssm-agent
sudo systemctl enable nginx amazon-ssm-agent

# 3. Nginx ProxyPass 설정 (Web -> WAS 연결용)
# 도메인으로 들어오는 트래픽을 내부 ALB로 전달
cat << EOF > /etc/nginx/conf.d/proxy.conf
server {
    listen 80;
    server_name ddongteacher.xyz;

    location /app {
        proxy_pass http://${alb_dns}/;
    }

    error_log /var/log/nginx/mark_error.log;
    access_log /var/log/nginx/mark_access.log combined;
}
EOF

# 4. EC2 메타데이터 조회 (IMDSv2 토큰 사용)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)

RZAZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
IID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  -s http://169.254.169.254/latest/meta-data/instance-id)
LIP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  -s http://169.254.169.254/latest/meta-data/local-ipv4)

# 5. 메인 인덱스 페이지(HTML) 생성
cat << EOF > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Web Server</title>
    <style>
        body { font-family: Arial, sans-serif; font-size: 50px; margin: 0; padding: 20px; }
        h1 { font-weight: bold; font-size: 50px; margin: 0 0 20px 0; }
        .info { font-weight: normal; font-size: 40px; line-height: 1.5; }
        .info br { margin-bottom: 10px; }
    </style>
</head>
<body>
    <h1>Web Server</h1>
    <div class="info">
        Region/AZ: $RZAZ<br>
        Instance ID: $IID<br>
        Private IP: $LIP<br>
    </div>
</body>
</html>
EOF

# 6. 설정 적용을 위한 Nginx 재시작
sudo systemctl restart nginx
