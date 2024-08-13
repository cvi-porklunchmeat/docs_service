module "tfm_aws_ecs" {
  source    = "git::https://github.com/cloud-investors/tfm_aws_ecs.git?ref=v5.1.0"
  namespace = var.namespace
  providers = {
    aws.network = aws.network
  }
  app_name       = "doc-service"
  app_short_name = "doc-service"
  app_fqdn       = "docs.abcloud.cloud"
  vpc_id         = module.tfm_aws_network.vpc_outputs.vpc_id
  subnet_ids     = module.tfm_aws_network.vpc_outputs.private_subnets
  task_cpu       = 1024
  task_ram       = 2048
  app_count      = 1
  container_definitions = [
    {
      "image" : "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${lower(var.namespace)}-${lower(var.reponame)}:${var.git_sha}",
      "cpu" : 1024,
      "memory" : 2048,
      "name" : "doc",
      "essential" : true,
      "environment" : [],
      "secrets" : [
        {
          "name" : "OKTA_CLIENT_ID",
          "valueFrom" : "${aws_secretsmanager_secret.okta.arn}:OKTA_CLIENT_ID::"
        },
        {
          "name" : "NEXTAUTH_URL",
          "valueFrom" : "${aws_secretsmanager_secret.okta.arn}:NEXTAUTH_URL::"
        },
        {
          "name" : "API_URL",
          "valueFrom" : "${aws_secretsmanager_secret.okta.arn}:API_URL::"
        },
        {
          "name" : "OKTA_CLIENT_SECRET",
          "valueFrom" : "${aws_secretsmanager_secret.okta.arn}:OKTA_CLIENT_SECRET::"
        },
        {
          "name" : "NEXTAUTH_SECRET",
          "valueFrom" : "${aws_secretsmanager_secret.okta.arn}:NEXTAUTH_SECRET::"
        },
        {
          "name" : "OKTA_ISSUER",
          "valueFrom" : "${aws_secretsmanager_secret.okta.arn}:OKTA_ISSUER::"
        },
        {
          "name" : "NEXT_PUBLIC_ADOBE_API_KEY",
          "valueFrom" : "${aws_secretsmanager_secret.okta.arn}:NEXT_PUBLIC_ADOBE_API_KEY::"
        },
        {
          "name" : "AZURE_AD_CLIENT_ID",
          "valueFrom" : "${aws_secretsmanager_secret.okta.arn}:AZURE_AD_CLIENT_ID::"
        },
        {
          "name" : "AZURE_AD_CLIENT_SECRET",
          "valueFrom" : "${aws_secretsmanager_secret.okta.arn}:AZURE_AD_CLIENT_SECRET::"
        },
        {
          "name" : "AZURE_AD_TENANT_ID",
          "valueFrom" : "${aws_secretsmanager_secret.okta.arn}:AZURE_AD_TENANT_ID::"
        }
      ],
      "publish" : {
        "containerPort" : 3000,
        "containerProtocol" : "http",
        "containerIpProtocol" : "tcp",
        "lbPort" : 443,
        "lbProtocol" : "https",
        "lbIpProtocol" : "tcp",
        "lbhc_path" : "/",
        "lbhc_port" : 3000,
        "lbhc_protocol" : "http"
      },
      "portMappings" : [
        {
          "containerPort" : 3000,
          "protocol" : "tcp"
        }
      ]
    }
  ]

  # The IAM role bound to our containers
  task_role = {
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Effect   = "Allow"
        Resource = [aws_kms_key.ecr.arn]
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken"
        ],
        Resource = "*"
      }
    ]
  }

  task_exec_role = {
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["secretsmanager:GetSecretValue"]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.okta.arn
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Effect   = "Allow"
        Resource = [aws_kms_key.okta.arn, aws_kms_key.ecr.arn]
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken"
        ],
        Resource = "*"
      }
    ]
  }
  # The ALB security group
  alb_sg = {
    "egress" : [
      {
        "to_port" : 0,
        "protocol" : "-1",
        "from_port" : 0,
        "self" : null,
        "ipv6_cidr_blocks" : null,
        "cidr_blocks" : [
          "0.0.0.0/0"
        ]
      }
    ],
    "ingress" : [
      {
        "to_port" : 0,
        "protocol" : "-1",
        "from_port" : 0,
        "self" : null,
        "ipv6_cidr_blocks" : null,
        "cidr_blocks" : [
          "10.0.0.0/8",
          "172.16.0.0/12",
          "192.168.0.0/16"
        ]
      }
    ]
  }
  # The Task security group
  task_sg = {
    "egress" : [
      {
        "to_port" : 0,
        "protocol" : "-1",
        "from_port" : 0,
        "self" : null,
        "ipv6_cidr_blocks" : null,
        "cidr_blocks" : [
          "0.0.0.0/0"
        ]
      }
    ],
    "ingress" : []
  }
}

