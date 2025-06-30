# modules/msk_kafka/main.tf

resource "aws_msk_cluster" "main" {
  cluster_name           = "${var.project_name}-kafka-cluster"
  kafka_version          = "3.6.0" # Choose a recent stable version compatible with Kraft
  number_of_broker_nodes = var.number_of_broker_nodes

  broker_node_group_info {
    instance_type   = var.broker_instance_type
    ebs_volume_size = 100 # GB
    client_subnets = var.private_subnets_ids
    security_groups = [var.security_group_id]
  }

  client_authentication {
    sasl {
      iam = true # Recommended for production for granular IAM control
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS_PLAINTEXT" # For now, allow plaintext from clients
      in_cluster    = true
    }
    at_rest_encryption {
      data_volume_kms_key_id = "Default" # Use AWS managed KMS key
    }
  }

  tags = {
    Name    = "${var.project_name}-kafka-cluster"
    Project = var.project_name
  }
}