data "aws_iam_policy_document" "permit_cert_export" {
  statement {
    effect    = length(aws_acm_certificate.this) > 0 ? "Allow" : "Deny"
    actions   = ["acm:ExportCertificate"]
    resources = [length(aws_acm_certificate.this) > 0 ? aws_acm_certificate.this[0].arn : "*"]
  }
}

resource "aws_iam_policy" "permit_cert_export" {
  name   = "${local.short_name}-acm"
  policy = data.aws_iam_policy_document.permit_cert_export.json
}

resource "aws_iam_role_policy_attachment" "this_cert_export" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.permit_cert_export.arn
}

data "aws_iam_policy_document" "ecs_agent" {
  count = var.on_ec2 == true ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_agent" {
  count              = var.on_ec2 == true ? 1 : 0
  name               = "${local.short_name}-ecs-agent"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent[0].json
  tags               = var.ec2_role_access_tags
}


resource "aws_iam_role_policy_attachment" "ecs_agent" {
  count      = var.on_ec2 == true ? 1 : 0
  role       = aws_iam_role.ecs_agent[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_agent_ssm" {
  count      = var.on_ec2 == true ? 1 : 0
  role       = aws_iam_role.ecs_agent[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  count = var.on_ec2 == true ? 1 : 0
  name  = "${local.short_name}-ecs-agent"
  role  = aws_iam_role.ecs_agent[0].name
}

resource "aws_iam_role_policy" "ecs_agent_custom" {
  count  = var.ec2_role != null && var.on_ec2 == true ? 1 : 0
  name   = "${local.short_name}-ecs-custom-ec2-role-policy"
  role   = aws_iam_role.ecs_agent[0].id
  policy = jsonencode(var.ec2_role)
}

resource "aws_iam_role" "exec_this" {
  name = "${local.short_name}-ecs-exec-task-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : { "Service" : "ecs-tasks.amazonaws.com" },
        "Action" : "sts:AssumeRole",
      }
    ],
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
}

resource "aws_iam_role" "this" {
  name = "${local.short_name}-ecs-task-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : { "Service" : "ecs-tasks.amazonaws.com" },
        "Action" : "sts:AssumeRole",
      }
    ],
  })
  tags = var.task_role_access_tags
}

# resource "aws_iam_role_policy" "exec_this" {
#   name = "${local.short_name}-ecs-exec-role-policy"
#   role = aws_iam_role.exec_this.id
#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "logs:CreateLogGroup",
#         ],
#         "Resource" : "*",
#       }
#     ]
#   })
# }

resource "aws_iam_role_policy" "this_exec_custom" {
  count  = var.task_exec_role != null ? 1 : 0
  name   = "${local.short_name}-ecs-custom-task-exec-role-policy"
  role   = aws_iam_role.exec_this.id
  policy = jsonencode(var.task_exec_role)
}

resource "aws_iam_role_policy" "this_custom" {
  count  = var.task_role != null ? 1 : 0
  name   = "${local.short_name}-ecs-custom-task-role-policy"
  role   = aws_iam_role.this.id
  policy = jsonencode(var.task_role)
}

resource "aws_iam_role_policy" "this" {
  name = "${local.short_name}-ecs-task-role-policy"
  role = aws_iam_role.this.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Deny",
        "Action" : "ssm:StartSession",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
        ],
        "Resource" : "*",
      },
      {
        "Effect" : "Allow",
        "Action" : ["logs:DescribeLogGroups"],
        "Resource" : "*",
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
        ],
        "Resource" : [
          "${aws_cloudwatch_log_group.this_commands.arn}:*",
          "${aws_cloudwatch_log_group.this_logs.arn}:*"
        ],
      },
      {
        "Effect" : "Allow",
        "Action" : ["kms:Decrypt"],
        "Resource" : "${aws_kms_key.this.arn}",
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
