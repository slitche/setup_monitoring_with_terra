resource "aws_route53_zone" "private_zone" {
  name = "internal"
  vpc {
    vpc_id = var.vpc_id
  }
}


resource "aws_route53_record" "prometheus_dns" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "prometheus.internal"
  type    = "A"
  ttl     = 300
  records = [aws_instance.prometheus-server.private_ip]
}


resource "aws_route53_record" "grafana_dns" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "grafana.internal"
  type    = "A"
  ttl     = 300
  records = [aws_instance.grafana-server.private_ip]
}


resource "aws_route53_record" "app_dns" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "app.internal"
  type    = "A"
  ttl     = 300
  records = [aws_instance.app-server.private_ip]
}

resource "aws_route53_record" "loki_dns" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "loki.internal"
  type    = "A"
  ttl     = 300
  records = [aws_instance.loki-server.private_ip]
}
