# modules/ecs_cluster/main.tf

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  tags = {
    Name    = "${var.project_name}-cluster"
    Project = var.project_name
  }
}

resource "aws_launch_configuration" "ecs_instance" {
  name_prefix                 = "${var.project_name}-ecs-lc-"
  image_id                    = data.aws_ami.ecs_optimized.id
  instance_type               = var.ecs_instance_type
  iam_instance_profile        = var.instance_profile_name
  security_groups             = [var.ecs_security_group_id]
  user_data                   = <<-EOF
                                    #!/bin/bash
                                    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
                                    sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${var.efs_id}.efs.${data.aws_region.current.name}.amazonaws.com:/ /opt/airflow/dags
                                    sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${var.efs_id}.efs.${data.aws_region.current.name}.amazonaws.com:/ /opt/airflow/logs
                                    sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${var.efs_id}.efs.${data.aws_region.current.name}.amazonaws.com:/ /opt/airflow/config
                                    sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${var.efs_id}.efs.${data.aws_region.current.name}.amazonaws.com:/ /opt/airflow/plugins
                                    sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${var.efs_id}.efs.${data.aws_region.current.name}.amazonaws.com:/ /opt/airflow/tasks
                                    EOF
  # IMPORTANT: The user_data above assumes EFS for shared Airflow volumes.
  # This needs to be configured in a separate EFS module and its ID passed here.
  # For local development, this might not be strictly necessary if you rebuild images with DAGs.

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_region" "current" {}

resource "aws_autoscaling_group" "ecs_asg" {
  name                      = "${var.project_name}-ecs-asg"
  launch_configuration      = aws_launch_configuration.ecs_instance.name
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.private_subnets_ids # Launch instances in private subnets
  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.project_name}-ecs-instance"
    propagate_at_launch = true
  }
  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }
}

resource "aws_ecr_repository" "airflow" {
  name = "airflow"
}

resource "aws_ecr_repository" "mlflow_webserver" {
  name = "mlflow-webserver"
}

resource "aws_ecr_repository" "kafka_ui" {
  name = "kafka-ui"
}

# You might want to create ECR repos for Grafana and Prometheus as well if you customize them
# For now, assuming direct pull from Docker Hub for these.