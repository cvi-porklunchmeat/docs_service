# data "aws_lb" "api" {
#   name = "pr-51-doc-service"
# }

# data "aws_lb_listener" "api" {
#   load_balancer_arn = data.aws_lb.api.arn
#   port              = 443
# }

# resource "aws_lb_target_group" "api" {
#   name_prefix = var.namespace
#   target_type = "ip"

#   health_check {
#     path     = "/"
#     port     = 443
#     protocol = "HTTPS"
#     matcher  = "200"
#   }

#   port     = 443
#   protocol = "HTTPS"
#   vpc_id   = module.tfm_aws_network.vpc_outputs.vpc_id

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_lb_target_group_attachment" "api" {
#   for_each         = toset(["eni-06b6ea67b91469ca0", "eni-0e8e8ded56597dbe6"])
#   target_group_arn = aws_lb_target_group.api.arn
#   target_id        = each.value
# }

# resource "aws_lb_listener_rule" "api" {
#   listener_arn = data.aws_lb_listener.api.arn
#   priority     = 50

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.api.arn
#   }

#   condition {
#     host_header {
#       values = ["api.pr-51-docs.abcloud.cloud"]
#     }
#   }
# }

# data "aws_route53_zone" "api" {
#   name         = "pr-51-docs.abcloud.cloud."
#   private_zone = true
# }

# resource "aws_route53_record" "cname" {
#   zone_id = data.aws_route53_zone.api.zone_id
#   name    = "api.${data.aws_route53_zone.api.name}"
#   type    = "CNAME"
#   ttl     = "5"
#   records = ["${aws_api_gateway_rest_api.gateway_api.id}-${module.tfm_aws_network.vpce_outputs.execute-api.endpoints.execute-api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com"]
# }


# data "aws_s3_objects" "frontend" {
#   bucket = aws_s3_bucket.frontend.bucket
# }

# resource "aws_lb" "frontend" {
#   name               = local.short_name
#   internal           = true
#   load_balancer_type = "application"
#   security_groups    = [module.tfm_aws_network.custom_sg.frontend.id]
#   subnets            = values(module.tfm_aws_network.private_subnets)

#   access_logs {
#     bucket  = aws_s3_bucket.alb.bucket
#     prefix  = local.short_name
#     enabled = true
#   }

# }

# resource "aws_lb_target_group" "s3_vpce" {
#   name_prefix = var.namespace
#   target_type = "ip"

#   health_check {
#     path     = "/"
#     port     = 80
#     protocol = "HTTP"
#     matcher  = "307"
#   }

#   port     = 443
#   protocol = "HTTPS"
#   vpc_id   = module.tfm_aws_network.vpc_outputs.vpc_id

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_lb_target_group" "frontend_lambda" {
#   name_prefix = var.namespace
#   target_type = "lambda"

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_lb_target_group_attachment" "frontend_lambda" {
#   target_group_arn = aws_lb_target_group.frontend_lambda.arn
#   target_id        = module.frontend_lambda_function.arn
#   depends_on       = [aws_lambda_permission.frontend]
# }


# resource "aws_lb_listener" "frontend_redirect" {
#   load_balancer_arn = aws_lb.frontend.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type = "redirect"

#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }

# resource "aws_lb_listener" "frontend" {
#   load_balancer_arn = aws_lb.frontend.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
#   certificate_arn   = aws_acm_certificate.frontend.arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.s3_vpce.arn
#   }
# }

# resource "aws_lb_target_group_attachment" "frontend" {
#   for_each         = data.aws_network_interface.s3_vpce
#   target_group_arn = aws_lb_target_group.s3_vpce.arn
#   target_id        = each.value.private_ip
# }

# resource "aws_lb_listener_rule" "index" {
#   listener_arn = aws_lb_listener.frontend.arn
#   priority     = 10

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.s3_vpce.arn
#   }

#   condition {
#     path_pattern {
#       values = ["/index.html"]
#     }
#   }
# }

# resource "aws_lb_listener_rule" "_next" {
#   listener_arn = aws_lb_listener.frontend.arn
#   priority     = 15

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.s3_vpce.arn
#   }

#   condition {
#     path_pattern {
#       values = ["/_next/*"]
#     }
#   }
# }

# resource "aws_lb_listener_rule" "upload" {
#   listener_arn = aws_lb_listener.frontend.arn
#   priority     = 20

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.s3_vpce.arn
#   }

#   condition {
#     path_pattern {
#       values = ["/upload.html"]
#     }
#   }
# }

# resource "aws_lb_listener_rule" "logo" {
#   listener_arn = aws_lb_listener.frontend.arn
#   priority     = 25

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.s3_vpce.arn
#   }

#   condition {
#     path_pattern {
#       values = ["/cloud-logo.png"]
#     }
#   }
# }

# resource "aws_lb_listener_rule" "not_found" {
#   listener_arn = aws_lb_listener.frontend.arn

#   priority = 30

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.s3_vpce.arn
#   }

#   condition {
#     path_pattern {
#       values = ["/404.html"]
#     }
#   }
# }

# resource "aws_lb_listener_rule" "frontend_lambda" {
#   listener_arn = aws_lb_listener.frontend.arn

#   priority = 1000

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.frontend_lambda.arn
#   }

#   condition {
#     path_pattern {
#       values = ["/*"]
#     }
#   }
# }
