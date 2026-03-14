# ALB
resource "aws_lb" "alb-web" {
    name = var.alb-web-name
    internal = false
    load_balancer_type = "application" # Application Load Balancer
    security_groups = [aws_security_group.alb-sg-web.id]
    subnets = [aws_subnet.pub-sub1.id, aws_subnet.pub-sub2.id]
}

resource "aws_lb" "alb-was" {
    name = var.alb-was-name
    internal = true
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb-sg-was.id]
    subnets = [aws_subnet.was-sub1.id, aws_subnet.was-sub2.id]
}

# TG-Web
resource "aws_lb_target_group" "tg-web" {
    name = var.tg-web-name
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.vpc.id
    health_check {
        path = "/"
        matcher = "200-299"
        # health check 위해 기대되는 http 응답 코드 범위(200~299: 성공 응답)
        interval = 5 # 5초마다 health check 수행
        timeout = 3 # 3초 내에 반환하지 않으면 실패로 간주
        healthy_threshold = 3
        # 성공적인 health check 횟수(연속적으로 건강한 것으로 간주되기 위함)
        unhealthy_threshold = 5
        # 실패한 health check 횟수(연속적으로 비건강한 것으로 간주되기 위함)
    }
}

resource "aws_lb_listener" "myhttp" {
  load_balancer_arn = aws_lb.alb-web.arn
  port = 80
  protocol = "HTTP"

  default_action {
    # 'redirect'를 'forward'로 바꿔서 바로 Web 서버로 보냄.
    type = "forward" 
    target_group_arn = aws_lb_target_group.tg-web.arn 
  }
}

# TG-WAS
resource "aws_lb_target_group" "tg-was" {
    name = var.tg-was-name
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.vpc.id
    health_check {
        path = "/"
        matcher = "200-299"
        interval = 5
        timeout = 3
        healthy_threshold = 3
        unhealthy_threshold = 5
    }
}

resource "aws_lb_listener" "alb_listener-was" {
    load_balancer_arn = aws_lb.alb-was.arn
    port = 80
    protocol = "HTTP"
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.tg-was.arn
    }
}
