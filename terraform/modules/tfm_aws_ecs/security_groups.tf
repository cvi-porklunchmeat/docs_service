resource "aws_security_group" "this_task" {
  for_each    = local.container_definitions
  name        = "${var.namespace}-${each.key}-task-sg"
  description = "Security Group for ${each.key} container definition"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.service == true && var.app_lb == true ? ["this"] : []
    content {
      description     = "Allow traffic from the ALB"
      security_groups = [aws_security_group.this_alb[0].id]
      from_port       = each.value.containerPort
      to_port         = each.value.containerPort
      protocol        = lower(each.value.containerIpProtocol)
    }
  }

  dynamic "ingress" {
    for_each = [for item in var.task_sg.ingress : {
      description      = item.description
      from_port        = item.from_port
      to_port          = item.to_port
      protocol         = item.protocol
      cidr_blocks      = item.cidr_blocks
      ipv6_cidr_blocks = item.ipv6_cidr_blocks
      self             = item.self
    } if var.service != true]
    content {
      description      = ingress.value.description
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = upper(ingress.value.protocol)
      cidr_blocks      = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      self             = ingress.value.self
    }
  }

  # Limit what the tasks can initiate traffic to
  dynamic "egress" {
    for_each = [for item in var.task_sg.egress : {
      description      = item.description
      from_port        = item.from_port
      to_port          = item.to_port
      protocol         = item.protocol
      cidr_blocks      = item.cidr_blocks
      ipv6_cidr_blocks = item.ipv6_cidr_blocks
      self             = item.self
    }]
    content {
      description      = egress.value.description
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = upper(egress.value.protocol)
      cidr_blocks      = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      self             = egress.value.self
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group" "this_alb" {
  count       = var.service == true && var.app_lb == true ? 1 : 0
  name        = "${var.namespace}-${var.app_short_name}-alb-sg"
  description = "Security Group for ${var.app_short_name} ALB"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = [for item in var.alb_sg.ingress : {
      description      = item.description
      from_port        = item.from_port
      to_port          = item.to_port
      protocol         = item.protocol
      cidr_blocks      = item.cidr_blocks
      ipv6_cidr_blocks = item.ipv6_cidr_blocks
      self             = item.self
    }]
    content {
      description      = ingress.value.description
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = upper(ingress.value.protocol)
      cidr_blocks      = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      self             = ingress.value.self

    }
  }
  dynamic "egress" {
    for_each = [for item in var.alb_sg.egress : {
      description      = item.description
      from_port        = item.from_port
      to_port          = item.to_port
      protocol         = item.protocol
      cidr_blocks      = item.cidr_blocks
      ipv6_cidr_blocks = item.ipv6_cidr_blocks
      self             = item.self
    }]
    content {
      description      = egress.value.description
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = upper(egress.value.protocol)
      cidr_blocks      = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      self             = egress.value.self
    }
  }
}

resource "aws_security_group" "ecs_ec2_sg" {
  count       = var.on_ec2 == true ? 1 : 0
  name        = "${var.namespace}-${var.app_short_name}-ec2-sg"
  description = "Security Group for ${var.app_short_name} EC2 cluster"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow all traffic from the ALB"
    security_groups = [aws_security_group.this_alb[0].id]
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
  }

  egress {
    description = "Allow all traffic outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
