# modules/ecs_services/main.tf

# ---------------------------------------------------
# Airflow Services
# ---------------------------------------------------

# Airflow Worker Task Definition
resource "aws_ecs_task_definition" "airflow_worker" {
  family                   = "${var.project_name}-airflow-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"] # Or Fargate if you decide to go serverless
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn # For S3, RDS, etc. if needed

  container_definitions = jsonencode([
    {
      name      = "airflow-worker"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/airflow:${var.airflow_image_tag}"
      command   = ["celery", "worker"]
      cpu       = 256
      memory    = 512
      essential = true
      environment = [
        { name = "PYTHONPATH", value = "/opt/airflow" },
        { name = "AIRFLOW__CORE__EXECUTOR", value = "CeleryExecutor" },
        { name = "AIRFLOW__CORE__AUTH_MANAGER", value = "airflow.providers.fab.auth_manager.fab_auth_manager.FabAuthManager" },
        { name = "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN", value = "postgresql+psycopg2://${var.airflow_db_username}:${var.airflow_db_password}@${var.airflow_db_host}/airflow" },
        { name = "AIRFLOW__CELERY__RESULT_BACKEND", value = "db+postgresql://${var.airflow_db_username}:${var.airflow_db_password}@${var.airflow_db_host}/airflow" },
        { name = "AIRFLOW__CELERY__BROKER_URL", value = "redis://:${var.airflow_redis_endpoint}" }, # Password if needed
        { name = "AIRFLOW__CORE__FERNET_KEY", value = var.airflow_fernet_key },
        { name = "AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION", value = "true" },
        { name = "AIRFLOW__CORE__LOAD_EXAMPLES", value = "false" },
        { name = "AIRFLOW__CORE__EXECUTION_API_SERVER_URL", value = "http://${aws_ecs_service.airflow_apiserver.name}:8080/execution/" }, # Assuming internal DNS for ECS
        { name = "AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK", value = "true" },
        { name = "_PIP_ADDITIONAL_REQUIREMENTS", value = "mlflow pandas scikit-learn pyarrow requests" },
        { name = "DUMB_INIT_SETSID", value = "0" }
      ]
      log_configuration {
        log_driver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/airflow-worker"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
      mount_points = [
        {
          sourceVolume = "airflow_dags"
          containerPath = "/opt/airflow/dags"
          readOnly = false
        },
        {
          sourceVolume = "airflow_logs"
          containerPath = "/opt/airflow/logs"
          readOnly = false
        },
        {
          sourceVolume = "airflow_config"
          containerPath = "/opt/airflow/config"
          readOnly = false
        },
        {
          sourceVolume = "airflow_plugins"
          containerPath = "/opt/airflow/plugins"
          readOnly = false
        },
        {
          sourceVolume = "airflow_tasks"
          containerPath = "/opt/airflow/tasks"
          readOnly = false
        }
      ]
    }
  ])

  volume {
    name = "airflow_dags"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/dags"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_dags.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_logs"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/logs"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_logs.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_config"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/config"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_config.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_plugins"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/plugins"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_plugins.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_tasks"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/tasks"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_tasks.id
        iam             = "ENABLED"
      }
    }
  }
}

resource "aws_efs_access_point" "airflow_dags" {
  file_system_id = var.efs_id
  posix_user {
    gid = 0
    uid = 50000 # Matches default AIRFLOW_UID
  }
  root_directory {
    path = "/dags"
    creation_info {
      owner_gid   = 0
      owner_uid   = 50000
      permissions = "0755"
    }
  }
}

resource "aws_efs_access_point" "airflow_logs" {
  file_system_id = var.efs_id
  posix_user {
    gid = 0
    uid = 50000
  }
  root_directory {
    path = "/logs"
    creation_info {
      owner_gid   = 0
      owner_uid   = 50000
      permissions = "0755"
    }
  }
}

resource "aws_efs_access_point" "airflow_config" {
  file_system_id = var.efs_id
  posix_user {
    gid = 0
    uid = 50000
  }
  root_directory {
    path = "/config"
    creation_info {
      owner_gid   = 0
      owner_uid   = 50000
      permissions = "0755"
    }
  }
}

resource "aws_efs_access_point" "airflow_plugins" {
  file_system_id = var.efs_id
  posix_user {
    gid = 0
    uid = 50000
  }
  root_directory {
    path = "/plugins"
    creation_info {
      owner_gid   = 0
      owner_uid   = 50000
      permissions = "0755"
    }
  }
}

resource "aws_efs_access_point" "airflow_tasks" {
  file_system_id = var.efs_id
  posix_user {
    gid = 0
    uid = 50000
  }
  root_directory {
    path = "/tasks"
    creation_info {
      owner_gid   = 0
      owner_uid   = 50000
      permissions = "0755"
    }
  }
}

resource "aws_ecs_service" "airflow_worker" {
  name            = "${var.project_name}-airflow-worker"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.airflow_worker.arn
  desired_count   = 1 # Adjust as needed
  launch_type     = "EC2"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_security_group_id]
    assign_public_ip = false
  }
  # Consider ECS Service Discovery for internal communication within ECS
  # service_registries {
  #   registry_arn = aws_service_discovery_service.airflow_api_server.arn
  # }

  depends_on = [
    aws_ecs_service.airflow_apiserver, # Depend on API server being up
    aws_ecs_service.airflow_scheduler,
    aws_ecs_service.airflow_init # Ensure init finishes before workers start trying to connect
  ]
}

# Airflow API Server Task Definition
resource "aws_ecs_task_definition" "airflow_apiserver" {
  family                   = "${var.project_name}-airflow-apiserver"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "airflow-apiserver"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/airflow:${var.airflow_image_tag}"
      command   = ["api-server"]
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "PYTHONPATH", value = "/opt/airflow" },
        { name = "AIRFLOW__CORE__EXECUTOR", value = "CeleryExecutor" },
        { name = "AIRFLOW__CORE__AUTH_MANAGER", value = "airflow.providers.fab.auth_manager.fab_auth_manager.FabAuthManager" },
        { name = "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN", value = "postgresql+psycopg2://${var.airflow_db_username}:${var.airflow_db_password}@${var.airflow_db_host}/airflow" },
        { name = "AIRFLOW__CELERY__RESULT_BACKEND", value = "db+postgresql://${var.airflow_db_username}:${var.airflow_db_password}@${var.airflow_db_host}/airflow" },
        { name = "AIRFLOW__CELERY__BROKER_URL", value = "redis://:${var.airflow_redis_endpoint}" },
        { name = "AIRFLOW__CORE__FERNET_KEY", value = var.airflow_fernet_key },
        { name = "AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION", value = "true" },
        { name = "AIRFLOW__CORE__LOAD_EXAMPLES", value = "false" },
        { name = "AIRFLOW__CORE__EXECUTION_API_SERVER_URL", value = "http://localhost:8080/execution/" }, # Self-referential for API server
        { name = "AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK", value = "true" },
        { name = "_PIP_ADDITIONAL_REQUIREMENTS", value = "mlflow pandas scikit-learn pyarrow requests" }
      ]
      log_configuration {
        log_driver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/airflow-apiserver"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
      mount_points = [
        {
          sourceVolume = "airflow_dags"
          containerPath = "/opt/airflow/dags"
          readOnly = true
        },
        {
          sourceVolume = "airflow_logs"
          containerPath = "/opt/airflow/logs"
          readOnly = true
        },
        {
          sourceVolume = "airflow_config"
          containerPath = "/opt/airflow/config"
          readOnly = true
        },
        {
          sourceVolume = "airflow_plugins"
          containerPath = "/opt/airflow/plugins"
          readOnly = true
        },
        {
          sourceVolume = "airflow_tasks"
          containerPath = "/opt/airflow/tasks"
          readOnly = true
        }
      ]
    }
  ])
  volume {
    name = "airflow_dags"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/dags"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_dags.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_logs"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/logs"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_logs.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_config"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/config"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_config.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_plugins"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/plugins"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_plugins.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_tasks"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/tasks"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_tasks.id
        iam             = "ENABLED"
      }
      }
    }
}

resource "aws_ecs_service" "airflow_apiserver" {
  name            = "${var.project_name}-airflow-apiserver"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.airflow_apiserver.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.airflow_api_server_target_group_arn
    container_name   = "airflow-apiserver"
    container_port   = 8080
  }

  depends_on = [
    aws_ecs_service.airflow_init # Ensure init finishes before API server starts
  ]
}

# Airflow Scheduler Task Definition
resource "aws_ecs_task_definition" "airflow_scheduler" {
  family                   = "${var.project_name}-airflow-scheduler"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "airflow-scheduler"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/airflow:${var.airflow_image_tag}"
      command   = ["scheduler"]
      cpu       = 256
      memory    = 512
      essential = true
      environment = [
        { name = "PYTHONPATH", value = "/opt/airflow" },
        { name = "AIRFLOW__CORE__EXECUTOR", value = "CeleryExecutor" },
        { name = "AIRFLOW__CORE__AUTH_MANAGER", value = "airflow.providers.fab.auth_manager.fab_auth_manager.FabAuthManager" },
        { name = "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN", value = "postgresql+psycopg2://${var.airflow_db_username}:${var.airflow_db_password}@${var.airflow_db_host}/airflow" },
        { name = "AIRFLOW__CELERY__RESULT_BACKEND", value = "db+postgresql://${var.airflow_db_username}:${var.airflow_db_password}@${var.airflow_db_host}/airflow" },
        { name = "AIRFLOW__CELERY__BROKER_URL", value = "redis://:${var.airflow_redis_endpoint}" },
        { name = "AIRFLOW__CORE__FERNET_KEY", value = var.airflow_fernet_key },
        { name = "AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION", value = "true" },
        { name = "AIRFLOW__CORE__LOAD_EXAMPLES", value = "false" },
        { name = "AIRFLOW__CORE__EXECUTION_API_SERVER_URL", value = "http://${aws_ecs_service.airflow_apiserver.name}:8080/execution/" },
        { name = "AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK", value = "true" },
        { name = "_PIP_ADDITIONAL_REQUIREMENTS", value = "mlflow pandas scikit-learn pyarrow requests" }
      ]
      log_configuration {
        log_driver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/airflow-scheduler"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
      mount_points = [
        {
          sourceVolume = "airflow_dags"
          containerPath = "/opt/airflow/dags"
          readOnly = false
        },
        {
          sourceVolume = "airflow_logs"
          containerPath = "/opt/airflow/logs"
          readOnly = false
        },
        {
          sourceVolume = "airflow_config"
          containerPath = "/opt/airflow/config"
          readOnly = false
        },
        {
          sourceVolume = "airflow_plugins"
          containerPath = "/opt/airflow/plugins"
          readOnly = false
        },
        {
          sourceVolume = "airflow_tasks"
          containerPath = "/opt/airflow/tasks"
          readOnly = false
        }
      ]
    }
  ])
  volume {
    name = "airflow_dags"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/dags"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_dags.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_logs"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/logs"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_logs.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_config"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/config"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_config.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_plugins"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/plugins"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_plugins.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_tasks"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/tasks"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_tasks.id
        iam             = "ENABLED"
      }
    }
  }
}

resource "aws_ecs_service" "airflow_scheduler" {
  name            = "${var.project_name}-airflow-scheduler"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.airflow_scheduler.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  depends_on = [
    aws_ecs_service.airflow_apiserver, # Depend on API server
    aws_ecs_service.airflow_init
  ]
}

# Airflow DAG Processor Task Definition
resource "aws_ecs_task_definition" "airflow_dag_processor" {
  family                   = "${var.project_name}-airflow-dag-processor"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "airflow-dag-processor"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/airflow:${var.airflow_image_tag}"
      command   = ["dag-processor"]
      cpu       = 256
      memory    = 512
      essential = true
      environment = [
        { name = "PYTHONPATH", value = "/opt/airflow" },
        { name = "AIRFLOW__CORE__EXECUTOR", value = "CeleryExecutor" },
        { name = "AIRFLOW__CORE__AUTH_MANAGER", value = "airflow.providers.fab.auth_manager.fab_auth_manager.FabAuthManager" },
        { name = "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN", value = "postgresql+psycopg2://${var.airflow_db_username}:${var.airflow_db_password}@${var.airflow_db_host}/airflow" },
        { name = "AIRFLOW__CELERY__RESULT_BACKEND", value = "db+postgresql://${var.airflow_db_username}:${var.airflow_db_password}@${var.airflow_db_host}/airflow" },
        { name = "AIRFLOW__CELERY__BROKER_URL", value = "redis://:${var.airflow_redis_endpoint}" },
        { name = "AIRFLOW__CORE__FERNET_KEY", value = var.airflow_fernet_key },
        { name = "AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION", value = "true" },
        { name = "AIRFLOW__CORE__LOAD_EXAMPLES", value = "false" },
        { name = "AIRFLOW__CORE__EXECUTION_API_SERVER_URL", value = "http://${aws_ecs_service.airflow_apiserver.name}:8080/execution/" },
        { name = "AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK", value = "true" },
        { name = "_PIP_ADDITIONAL_REQUIREMENTS", value = "mlflow pandas scikit-learn pyarrow requests" }
      ]
      log_configuration {
        log_driver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/airflow-dag-processor"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
      mount_points = [
        {
          sourceVolume = "airflow_dags"
          containerPath = "/opt/airflow/dags"
          readOnly = false
        },
        {
          sourceVolume = "airflow_logs"
          containerPath = "/opt/airflow/logs"
          readOnly = false
        },
        {
          sourceVolume = "airflow_config"
          containerPath = "/opt/airflow/config"
          readOnly = false
        },
        {
          sourceVolume = "airflow_plugins"
          containerPath = "/opt/airflow/plugins"
          readOnly = false
        },
        {
          sourceVolume = "airflow_tasks"
          containerPath = "/opt/airflow/tasks"
          readOnly = false
        }
      ]
    }
  ])
  volume {
    name = "airflow_dags"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/dags"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_dags.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_logs"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/logs"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_logs.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_config"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/config"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_config.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_plugins"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/plugins"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_plugins.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_tasks"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/tasks"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_tasks.id
        iam             = "ENABLED"
      }
    }
  }
}

resource "aws_ecs_service" "airflow_dag_processor" {
  name            = "${var.project_name}-airflow-dag-processor"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.airflow_dag_processor.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  depends_on = [
    aws_ecs_service.airflow_apiserver,
    aws_ecs_service.airflow_init
  ]
}

# Airflow Triggerer Task Definition
resource "aws_ecs_task_definition" "airflow_triggerer" {
  family                   = "${var.project_name}-airflow-triggerer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "airflow-triggerer"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/airflow:${var.airflow_image_tag}"
      command   = ["triggerer"]
      cpu       = 256
      memory    = 512
      essential = true
      environment = [
        { name = "PYTHONPATH", value = "/opt/airflow" },
        { name = "AIRFLOW__CORE__EXECUTOR", value = "CeleryExecutor" },
        { name = "AIRFLOW__CORE__AUTH_MANAGER", value = "airflow.providers.fab.auth_manager.fab_auth_manager.FabAuthManager" },
        { name = "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN", value = "postgresql+psycopg2://${var.airflow_db_username}:${var.airflow_db_password}@${var.airflow_db_host}/airflow" },
        { name = "AIRFLOW__CELERY__RESULT_BACKEND", value = "db+postgresql://${var.airflow_db_username}:${var.airflow_db_password}@${var.airflow_db_host}/airflow" },
        { name = "AIRFLOW__CELERY__BROKER_URL", value = "redis://:${var.airflow_redis_endpoint}" },
        { name = "AIRFLOW__CORE__FERNET_KEY", value = var.airflow_fernet_key },
        { name = "AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION", value = "true" },
        { name = "AIRFLOW__CORE__LOAD_EXAMPLES", value = "false" },
        { name = "AIRFLOW__CORE__EXECUTION_API_SERVER_URL", value = "http://${aws_ecs_service.airflow_apiserver.name}:8080/execution/" },
        { name = "AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK", value = "true" },
        { name = "_PIP_ADDITIONAL_REQUIREMENTS", value = "mlflow pandas scikit-learn pyarrow requests" }
      ]
      log_configuration {
        log_driver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/airflow-triggerer"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
      mount_points = [
        {
          sourceVolume = "airflow_dags"
          containerPath = "/opt/airflow/dags"
          readOnly = true
        },
        {
          sourceVolume = "airflow_logs"
          containerPath = "/opt/airflow/logs"
          readOnly = false
        },
        {
          sourceVolume = "airflow_config"
          containerPath = "/opt/airflow/config"
          readOnly = true
        },
        {
          sourceVolume = "airflow_plugins"
          containerPath = "/opt/airflow/plugins"
          readOnly = true
        },
        {
          sourceVolume = "airflow_tasks"
          containerPath = "/opt/airflow/tasks"
          readOnly = true
        }
      ]
    }
  ])
  volume {
    name = "airflow_dags"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/dags"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_dags.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_logs"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/logs"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_logs.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_config"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/config"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_config.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_plugins"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/plugins"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_plugins.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_tasks"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/tasks"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_tasks.id
        iam             = "ENABLED"
      }
    }
  }
}

resource "aws_ecs_service" "airflow_triggerer" {
  name            = "${var.project_name}-airflow-triggerer"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.airflow_triggerer.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  depends_on = [
    aws_ecs_service.airflow_apiserver,
    aws_ecs_service.airflow_init
  ]
}

# Airflow Init Task Definition (Run once for DB migrations and user creation)
resource "aws_ecs_task_definition" "airflow_init" {
  family                   = "${var.project_name}-airflow-init"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "airflow-init"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/airflow:${var.airflow_image_tag}"
      command   = ["/bin/bash", "/usr/local/bin/init_airflow_webserver.sh"] # Custom script for init
      cpu       = 256
      memory    = 512
      essential = true
      environment = [
        { name = "PYTHONPATH", value = "/opt/airflow" },
        { name = "AIRFLOW__CORE__EXECUTOR", value = "CeleryExecutor" },
        { name = "AIRFLOW__CORE__AUTH_MANAGER", value = "airflow.providers.fab.auth_manager.fab_auth_manager.FabAuthManager" },
        { name = "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN", value = "postgresql+psycopg2://${var.airflow_db_username}:${var.airflow_db_password}@${var.airflow_db_host}/airflow" },
        { name = "AIRFLOW__CELERY__RESULT_BACKEND", value = "db+postgresql://${var.airflow_db_username}:${var.airflow_db_password}@${var.airflow_db_host}/airflow" },
        { name = "AIRFLOW__CELERY__BROKER_URL", value = "redis://:${var.airflow_redis_endpoint}" },
        { name = "AIRFLOW__CORE__FERNET_KEY", value = var.airflow_fernet_key },
        { name = "AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION", value = "true" },
        { name = "AIRFLOW__CORE__LOAD_EXAMPLES", value = "false" },
        { name = "AIRFLOW__CORE__EXECUTION_API_SERVER_URL", value = "http://${aws_ecs_service.airflow_apiserver.name}:8080/execution/" },
        { name = "AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK", value = "true" },
        { name = "_PIP_ADDITIONAL_REQUIREMENTS", value = "mlflow pandas scikit-learn pyarrow requests" },
        { name = "_AIRFLOW_DB_MIGRATE", value = "true" },
        { name = "_AIRFLOW_WWW_USER_CREATE", value = "true" },
        { name = "_AIRFLOW_WWW_USER_USERNAME", value = var.airflow_admin_username },
        { name = "_AIRFLOW_WWW_USER_PASSWORD", value = var.airflow_admin_password },
        { name = "AIRFLOW_UID", value = "50000" } # Hardcoding for init
      ]
      log_configuration {
        log_driver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/airflow-init"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
      mount_points = [
        {
          sourceVolume = "airflow_dags"
          containerPath = "/opt/airflow/dags"
          readOnly = false
        },
        {
          sourceVolume = "airflow_logs"
          containerPath = "/opt/airflow/logs"
          readOnly = false
        },
        {
          sourceVolume = "airflow_config"
          containerPath = "/opt/airflow/config"
          readOnly = false
        },
        {
          sourceVolume = "airflow_plugins"
          containerPath = "/opt/airflow/plugins"
          readOnly = false
        },
        {
          sourceVolume = "airflow_tasks"
          containerPath = "/opt/airflow/tasks"
          readOnly = false
        }
      ]
    }
  ])
  volume {
    name = "airflow_dags"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/dags"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_dags.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_logs"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/logs"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_logs.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_config"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/config"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_config.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_plugins"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/plugins"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_plugins.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "airflow_tasks"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/tasks"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.airflow_tasks.id
        iam             = "ENABLED"
      }
    }
  }
}

resource "aws_ecs_service" "airflow_init" {
  name            = "${var.project_name}-airflow-init"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.airflow_init.arn
  desired_count   = 1 # Run once
  launch_type     = "EC2"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  lifecycle {
    ignore_changes = [desired_count] # Only run on initial deploy
  }
}

# Airflow CLI and Flower are typically for dev/debug and can be run manually or as ephemeral tasks.
# We won't deploy them as persistent services here for a production-like setup.
# If needed, they can be added with their own task definitions and services.

# ---------------------------------------------------
# MLflow Services
# ---------------------------------------------------

# MLflow Webserver Task Definition
resource "aws_ecs_task_definition" "mlflow_webserver" {
  family                   = "${var.project_name}-mlflow-webserver"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "mlflow-webserver"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/mlflow-webserver:${var.mlflow_image_tag}"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "MLFLOW_FLASK_SERVER_SECRET_KEY", value = "mlflow_secret_key" }, # Consider AWS Secrets Manager
        { name = "MLFLOW_TRACKING_USERNAME", value = "mlflow" }, # Consider AWS Secrets Manager
        { name = "MLFLOW_TRACKING_PASSWORD", value = "mlflow" }, # Consider AWS Secrets Manager
        { name = "BACKEND_URI", value = "postgresql://mlflow:${var.mlflow_db_password}@${var.mlflow_db_host}:5432" },
        { name = "MLFLOW_S3_ENDPOINT_URL", value = "https://s3.${data.aws_region.current.name}.amazonaws.com" }, # Use official S3 endpoint
        { name = "ARTIFACT_ROOT", value = "s3://${var.mlflow_s3_bucket_name}/" },
        # For production, prefer IAM roles on task definition over direct keys
        # { name = "AWS_ACCESS_KEY_ID", value = var.mlflow_access_key_id },
        # { name = "AWS_SECRET_ACCESS_KEY", value = var.mlflow_secret_access_key }
      ]
      log_configuration {
        log_driver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/mlflow-webserver"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "mlflow_webserver" {
  name            = "${var.project_name}-mlflow-webserver"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.mlflow_webserver.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.mlflow_webserver_target_group_arn
    container_name   = "mlflow-webserver"
    container_port   = 5000
  }
}

# ---------------------------------------------------
# Kafka UI Service
# ---------------------------------------------------

resource "aws_ecs_task_definition" "kafka_ui" {
  family                   = "${var.project_name}-kafka-ui"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "kafka-ui"
      image     = var.kafka_ui_image_tag
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8081 # Exposed port in docker-compose for UI access
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "KAFKA_CLUSTERS_0_NAME", value = "kraft-cluster" },
        { name = "KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS", value = var.kafka_brokers }
      ]
      log_configuration {
        log_driver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/kafka-ui"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "kafka_ui" {
  name            = "${var.project_name}-kafka-ui"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.kafka_ui.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.kafka_ui_target_group_arn
    container_name   = "kafka-ui"
    container_port   = 8080 # Internal container port
  }

  depends_on = [
    aws_msk_cluster.main # Depend on MSK cluster being ready
  ]
}

# ---------------------------------------------------
# Monitoring Services
# ---------------------------------------------------

# Prometheus Task Definition
resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${var.project_name}-prometheus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "prometheus"
      image     = var.prometheus_image_tag
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 9090
          hostPort      = 9090
          protocol      = "tcp"
        }
      ]
      command = [
        "--config.file=/etc/prometheus/prometheus.yml",
        "--storage.tsdb.path=/prometheus",
        "--web.console.libraries=/usr/share/prometheus/console_libraries",
        "--web.console.templates=/usr/share/prometheus/consoles"
      ]
      mount_points = [
        {
          sourceVolume = "prometheus_config"
          containerPath = "/etc/prometheus/prometheus.yml"
          readOnly = true
        },
        {
          sourceVolume = "prometheus_data"
          containerPath = "/prometheus"
          readOnly = false
        }
      ]
      log_configuration {
        log_driver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/prometheus"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  volume {
    name = "prometheus_config"
    host_path = "/tmp/${var.project_name}/prometheus.yml" # Assumes Prometheus config is mounted via host path.
                                                     # Better: use SSM Parameter Store or S3 for config management.
                                                     # For now, it's just a placeholder and you'd manually sync.
  }
  volume {
    name = "prometheus_data"
    host_path = "/tmp/${var.project_name}/prometheus_data" # Persistent storage for Prometheus data
  }
}

resource "aws_ecs_service" "prometheus" {
  name            = "${var.project_name}-prometheus"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.prometheus_target_group_arn
    container_name   = "prometheus"
    container_port   = 9090
  }
}

# Grafana Task Definition
resource "aws_ecs_task_definition" "grafana" {
  family                   = "${var.project_name}-grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "grafana"
      image     = var.grafana_image_tag
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "GF_SECURITY_ADMIN_PASSWORD", value = var.grafana_admin_password }
      ]
      mount_points = [
        {
          sourceVolume = "grafana_data"
          containerPath = "/var/lib/grafana"
          readOnly = false
        }
      ]
      log_configuration {
        log_driver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/grafana"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  volume {
    name = "grafana_data"
    host_path = "/tmp/${var.project_name}/grafana_data" # Persistent storage for Grafana data
  }
}

resource "aws_ecs_service" "grafana" {
  name            = "${var.project_name}-grafana"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.grafana_target_group_arn
    container_name   = "grafana"
    container_port   = 3000
  }

  depends_on = [
    aws_ecs_service.prometheus
  ]
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# CloudWatch Log Groups for each service
resource "aws_cloudwatch_log_group" "airflow_worker" {
  name              = "/ecs/airflow-worker"
  retention_in_days = 7 # Adjust retention as needed
}

resource "aws_cloudwatch_log_group" "airflow_apiserver" {
  name              = "/ecs/airflow-apiserver"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "airflow_scheduler" {
  name              = "/ecs/airflow-scheduler"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "airflow_dag_processor" {
  name              = "/ecs/airflow-dag-processor"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "airflow_triggerer" {
  name              = "/ecs/airflow-triggerer"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "airflow_init" {
  name              = "/ecs/airflow-init"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "mlflow_webserver" {
  name              = "/ecs/mlflow-webserver"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "kafka_ui" {
  name              = "/ecs/kafka-ui"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "prometheus" {
  name              = "/ecs/prometheus"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/ecs/grafana"
  retention_in_days = 7
}