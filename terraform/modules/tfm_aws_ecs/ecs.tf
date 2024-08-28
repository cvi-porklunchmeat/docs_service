locals {
  cert_arn = length(aws_acm_certificate.this) > 0 ? [{ "name" : "ACM_PRIVATE_CERT_ARN", "value" : aws_acm_certificate.this[0].arn }] : []
  # We force all containers to log their output, and this logic does that
  containers_with_logging = [for container in var.container_definitions : merge(container, {
    "logConfiguration" : {
      "logDriver" : "awslogs",
      "options" : {
        "awslogs-group" : "${local.short_name}/logs",
        "awslogs-region" : data.aws_region.current.name,
        "awslogs-stream-prefix" : container.name
      }
    },
    "environment" : concat(container.environment, local.cert_arn)
  })]
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.short_name
  network_mode             = var.network_mode
  requires_compatibilities = [var.on_ec2 == true ? "EC2" : "FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_ram
  execution_role_arn       = aws_iam_role.exec_this.arn
  task_role_arn            = aws_iam_role.this.arn
  container_definitions    = jsonencode(local.containers_with_logging)
  dynamic "volume" {
    for_each = var.volume
    content {
      host_path = lookup(volume.value, "host_path", null)
      name      = volume.value.source_volume

      dynamic "efs_volume_configuration" {
        for_each = lookup(volume.value, "efs_volume_configuration", [])
        content {
          file_system_id     = lookup(efs_volume_configuration.value, "file_system_id", null)
          root_directory     = lookup(efs_volume_configuration.value, "root_directory", null)
          transit_encryption = "ENABLED"
          dynamic "authorization_config" {
            for_each = efs_volume_configuration.value.authorization_config

            content {
              iam             = authorization_config.value.iam
              access_point_id = authorization_config.value.access_point_id
            }
          }
        }
      }

      dynamic "docker_volume_configuration" {
        for_each = lookup(volume.value, "docker_volume_configuration", [])
        content {
          scope         = lookup(docker_volume_configuration.value, "scope", null)
          autoprovision = lookup(docker_volume_configuration.value, "autoprovision", null)
          driver        = lookup(docker_volume_configuration.value, "driver", null)
          driver_opts   = lookup(docker_volume_configuration.value, "driver_opts", null)
          labels        = lookup(docker_volume_configuration.value, "labels", null)
        }
      }
    }
  }
}

data "aws_ami" "cluster_ami" {
  count       = var.on_ec2 == true ? 1 : 0
  most_recent = true

  filter {
    name   = "name"
    values = [var.ec2_config.ami.name]
  }

  filter {
    name   = "virtualization-type"
    values = [var.ec2_config.ami.virtualization_type]
  }

  owners = [var.ec2_config.ami.owner]
}

resource "aws_launch_template" "ec2" {
  count                  = var.on_ec2 == true ? 1 : 0
  name_prefix            = local.short_name
  description            = "${local.short_name} launch template"
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
    }
  }

  ebs_optimized = true

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_agent[0].name
  }

  image_id                             = data.aws_ami.cluster_ami[0].id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = var.ec2_config.instance_size

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [aws_security_group.ecs_ec2_sg[0].id]

  user_data = var.ec2_config.user_data != null ? var.ec2_config.user_data : base64encode(templatefile("${path.module}/user_data.tftpl", { local_name = local.short_name }))
}

resource "aws_autoscaling_group" "ec2" {
  count               = var.on_ec2 == true ? 1 : 0
  name_prefix         = local.short_name
  vpc_zone_identifier = var.subnet_ids
  #launch_configuration = aws_launch_configuration.ecs_launch_config[0].name

  launch_template {
    id      = aws_launch_template.ec2[0].id
    version = aws_launch_template.ec2[0].latest_version
  }

  instance_refresh {
    strategy = "Rolling"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }

  desired_capacity          = var.ec2_config.desired_capacity
  min_size                  = var.ec2_config.min_size
  max_size                  = var.ec2_config.max_size
  health_check_grace_period = var.ec2_config.health_check_grace_period
  health_check_type         = var.ec2_config.health_check_type
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

resource "aws_ecs_capacity_provider" "ec2" {
  count = var.on_ec2 == true ? 1 : 0
  name  = local.short_name

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ec2[0].arn

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 10
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  count        = var.on_ec2 == true ? 1 : 0
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = [aws_ecs_capacity_provider.ec2[0].name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ec2[0].name
  }
}

resource "aws_ecs_cluster" "this" {
  name = local.short_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.this.arn
      logging    = "OVERRIDE"
      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.this_commands.name
      }
    }
  }
}

resource "aws_ecs_service" "this" {
  count                             = var.service == true ? 1 : 0
  name                              = local.short_name
  cluster                           = aws_ecs_cluster.this.id
  task_definition                   = aws_ecs_task_definition.this.arn
  force_new_deployment              = true
  wait_for_steady_state             = var.wait_for_steady_state
  desired_count                     = var.app_count
  launch_type                       = var.on_ec2 == true ? "EC2" : "FARGATE"
  enable_execute_command            = lower(var.namespace) == "prod" ? false : true
  health_check_grace_period_seconds = var.app_lb == true ? var.health_check_grace_period : null

  dynamic "load_balancer" {
    for_each = var.app_lb == true ? local.container_definitions : {}
    content {
      target_group_arn = lookup(aws_lb_target_group.this, load_balancer.value.name).arn
      container_name   = load_balancer.value.name
      container_port   = load_balancer.value.containerPort
    }
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [for sg in aws_security_group.this_task : sg.id]
    assign_public_ip = false
  }

  triggers = {
    redeployment = true
  }

  depends_on = [
    aws_lb_listener.this
  ]
}

