output "web-alb-dns" {
  value = aws_lb.alb-web.dns_name
}

output "rds-endpoint" {
  value = data.aws_db_instance.my_rds.endpoint
}
