# modules/application_load_balancer/main.tf

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnets_ids

  tags = {
    Name    = "${var.project_name}-alb"
    Project = var.project_name
  }
}

# Airflow API Server Target Group & Listener
resource "aws_lb_target_group" "airflow_api_server" {
  name     = "${var.project_name}-airflow-apiserver-tg"
  port     = var.airflow_webserver_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip" # ECS Fargate or IP-based targets

  health_check {
    path = "/api/v2/version"
    protocol = "HTTP"
    matcher = "200"
    interval = 30 # seconds
    timeout = 10 # seconds
    healthy_threshold = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name    = "${var.project_name}-airflow-apiserver-tg"
    Project = var.project_name
  }
}

resource "aws_lb_listener" "airflow_api_server" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.airflow_webserver_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.airflow_api_server.arn
  }
}

# Airflow Webserver Target Group & Listener (if exposed)
resource "aws_lb_target_group" "airflow_webserver" {
  name     = "${var.project_name}-airflow-webserver-tg"
  port     = 8080 # Same as api-server for local dev, might change in prod for webserver UI
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 30 # seconds
    timeout = 10 # seconds
    healthy_threshold = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name    = "${var.project_name}-airflow-webserver-tg"
    Project = var.project_name
  }
}

resource "aws_lb_listener" "airflow_webserver" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.airflow_webserver.arn
  }
}

# MLflow Webserver Target Group & Listener
resource "aws_lb_target_group" "mlflow_webserver" {
  name     = "${var.project_name}-mlflow-webserver-tg"
  port     = var.mlflow_webserver_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 30 # seconds
    timeout = 10 # seconds
    healthy_threshold = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name    = "${var.project_name}-mlflow-webserver-tg"
    Project = var.project_name
  }
}

resource "aws_lb_listener" "mlflow_webserver" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.mlflow_webserver_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mlflow_webserver.arn
  }
}

# Kafka UI Target Group & Listener
resource "aws_lb_target_group" "kafka_ui" {
  name     = "${var.project_name}-kafka-ui-tg"
  port     = var.kafka_ui_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 30 # seconds
    timeout = 10 # seconds
    healthy_threshold = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name    = "${var.project_name}-kafka-ui-tg"
    Project = var.project_name
  }
}

resource "aws_lb_listener" "kafka_ui" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.kafka_ui_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kafka_ui.arn
  }
}

# Grafana Target Group & Listener
resource "aws_lb_target_group" "grafana" {
  name     = "${var.project_name}-grafana-tg"
  port     = var.grafana_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 30 # seconds
    timeout = 10 # seconds
    healthy_threshold = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name    = "${var.project_name}-grafana-tg"
    Project = var.project_name
  }
}

resource "aws_lb_listener" "grafana" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.grafana_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}

# Prometheus Target Group & Listener
resource "aws_lb_target_group" "prometheus" {
  name     = "${var.project_name}-prometheus-tg"
  port     = var.prometheus_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/-/healthy" # Prometheus health check endpoint
    protocol = "HTTP"
    matcher = "200"
    interval = 30 # seconds
    timeout = 10 # seconds
    healthy_threshold = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name    = "${var.project_name}-prometheus-tg"
    Project = var.project_name
  }
}

resource "aws_lb_listener" "prometheus" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.prometheus_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus.arn
  }
}