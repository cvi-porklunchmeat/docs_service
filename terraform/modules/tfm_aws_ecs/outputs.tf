output "namespace" {
  value = var.namespace
}

output "ecs_url" {
  value = var.service == true && length(aws_lb.this) > 0 ? aws_lb.this[0].dns_name : null
}

output "cert_fqdn" {
  value = var.service == true && length(aws_acm_certificate.this) > 0 ? aws_acm_certificate.this[0].domain_name : null
}

output "cert_arn" {
  value = var.service == true && length(aws_acm_certificate.this) > 0 ? aws_acm_certificate.this[0].arn : null
}

output "cert_status" {
  value = var.service == true && length(aws_acm_certificate.this) > 0 ? aws_acm_certificate.this[0].status : null
}

output "cert_start" {
  value = var.service == true && length(aws_acm_certificate.this) > 0 ? aws_acm_certificate.this[0].not_before : null
}

output "cert_end" {
  value = var.service == true && length(aws_acm_certificate.this) > 0 ? aws_acm_certificate.this[0].not_after : null
}

output "ecs_cluster" {
  value = aws_ecs_cluster.this
}

output "aws_ecs_service" {
  value = var.service == true && length(aws_ecs_service.this) > 0 ? aws_ecs_service.this[0] : null
}

output "task_sg" {
  value = {
    for k, this_task in aws_security_group.this_task : k => this_task
  }
}

output "task_definition" {
  value = aws_ecs_task_definition.this
}

output "task_role_arn" {
  value = aws_iam_role.this.arn
}

output "task_exec_role_arn" {
  value = aws_iam_role.exec_this.arn
}

output "task_alb" {
  value = aws_lb.this[*]
}

output "task_alb_listener" {
  value = {
    for k, v in aws_lb_listener.this : k => v
  }
}

output "task_alb_target_group" {
  value = {
    for k, v in aws_lb_target_group.this : k => v
  }
}

output "lb_iterator" {
  value = local.container_definitions
}
