#!/bin/bash
# Amazon Linux 2 userdata script for setting up Nginx, PHP, and RDS connection

# 1. 시스템 업데이트 및 필수 패키지 설치
sudo yum update -y
sudo yum install -y nginx php php-mysqlnd amazon-ssm-agent mariadb105

# 2. 서비스 시작 및 자동 실행 설정
sudo systemctl start nginx amazon-ssm-agent
sudo systemctl enable nginx amazon-ssm-agent

# 3. 데이터베이스(RDS) 초기화 및 데이터 삽입
# 테라폼 변수(${host}, ${username} 등)를 받아와서 DB에 테이블을 만들고 데이터를 넣음.
mysql -h "${host}" -P 3306 -u "${username}" -p"${password}" "${db}" -e "
CREATE TABLE IF NOT EXISTS info (
    name VARCHAR(50) PRIMARY KEY,
    email VARCHAR(50),
    age INT
);"

mysql -h "${host}" -P 3306 -u "${username}" -p"${password}" "${db}" -e "
INSERT INTO info (name, email, age) 
VALUES ('mk', 'mk@google.com', 23)
ON DUPLICATE KEY UPDATE email=VALUES(email), age=VALUES(age);"

# 4. PHP 환경 확인 페이지 생성 (test.php)
cat << EOF > /usr/share/nginx/html/test.php
<?php
phpinfo();
?>
EOF

# 5. 실제 DB 연동 페이지 생성 (db.php)
cat << EOF > /usr/share/nginx/html/db.php
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>DB Page</title>
</head>
<body>
    <h1>DB Data List</h1>
    <?php
    // RDS 연결 설정
    $conn = new mysqli("${host}", "${username}", "${password}", "${db}", 3306);

    if ($conn->connect_error) {
        die("Connection failed: " . $conn->connect_error);
    }

    $sql = "SELECT name, email, age FROM info";
    $result = $conn->query($sql);

    if ($result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            echo "Name: " . $row["name"] . " | Email: " . $row["email"] . " | Age: " . $row["age"] . "<br>";
        }
    } else {
        echo "0 results";
    }
    $conn->close();
    ?>
</body>
</html>
EOF

# 6. 설정 적용을 위한 Nginx 재시작
sudo systemctl restart nginx
