variable "namespace" {
  description = "The namespace for this deployment"
  type        = string
}

variable "app_name" {
  description = "The full name of your application"
  type        = string
}

variable "app_short_name" {
  description = "The short name of your application"
  type        = string
}

variable "app_fqdn" {
  description = "The domain FQDN to create for your application"
  type        = string
  default     = ""
}

variable "app_sans" {
  description = "Additional names to add to the application certificate"
  type        = list(string)
  default     = []
}

variable "app_count" {
  description = "The number of instances of your app (containers) to create and balance traffic to."
  type        = number
  default     = null
}

variable "health_check_grace_period" {
  description = "The amount of seconds (delay) the ALB should wait before checking the health of our app"
  type        = number
  default     = 180 # 3 min
}

variable "cookie_duration" {
  description = "How long should the ALB cookie be valid for"
  type        = number
  default     = 28800 # 8 hours
}

variable "wait_for_steady_state" {
  description = "(Optional) If true, Terraform will wait for the service to reach a steady state (like aws ecs wait services-stable) before continuing. Default false"
  type        = bool
  default     = false
}

variable "task_role_access_tags" {
  description = "(Required) Tags that will be applied to your task role. Used for ABAC"
  type = object({
    access_project = string,
    access_team    = string,
    cost_center    = number
  })
  default = null
}


variable "ec2_role_access_tags" {
  description = "(Required) Tags that will be applied to your ECS EC2 instances. Used for ABAC"
  type = object({
    access_project = string,
    access_team    = string,
    cost_center    = number
  })
  default = null
}

variable "vpc_id" {
  description = "The VPC ID that we'll deploy this app into"
  type        = string
}

variable "subnet_ids" {
  description = "The subnet IDs of the subnets that we'll deploy this app into"
  type        = list(string)
}

variable "task_cpu" {
  description = "The CPU size for this task"
  type        = string
  default     = "1024"
}

variable "task_ram" {
  description = "The RAM size for this task"
  type        = string
  default     = "2048"
}

variable "alb_sg" {
  default = {}
}

variable "task_sg" {
  default = {}
}

variable "task_role" {
  description = "Policy to attach to the ECS task role. This is used after a task is running"
  default     = null
}

variable "ec2_role" {
  description = "Policy to attach to the EC2 instances when using an EC2 cluster"
  default     = null
}

variable "task_exec_role" {
  description = "Policy to attach to the ECS task exec role. This is used as a task is started"
  default     = null
}

variable "service" {
  description = "true will create a service and ALB. false will deploy just the cluster and task"
  type        = bool
  default     = true
}

variable "network_mode" {
  description = "The network mode to use for the task"
  type        = string
  default     = "awsvpc"
}

variable "on_ec2" {
  description = "true will deploy ECS onto EC2. false will deploy ECS onto Fargate"
  type        = bool
  default     = false
}

variable "ec2_config" {
  type = object({
    ami = optional(object({
      name                = optional(string, "amzn2-ami-ecs-hvm-2.0.20230109-x86_64-ebs")
      virtualization_type = optional(string, "hvm")
      owner               = optional(string, "591542846629")
    }), {})
    desired_capacity          = optional(number, 1)
    min_size                  = optional(number, 1)
    max_size                  = optional(number, 3)
    health_check_grace_period = optional(number, 300)
    health_check_type         = optional(string, "EC2")
    instance_size             = optional(string, "t3.medium")
    user_data                 = optional(string, null)
  })
  default = null
}

variable "volume" {
  description = "Used for a dynamic volume block for ECS service."
  type        = any
  default     = []
}

variable "app_lb" {
  description = "Used to determine if an application load balancer should be deployed in front of the service"
  type        = bool
  default     = true
}

variable "container_definitions" {
  type = list(object(
    {
      image                   = string,
      cpu                     = number,
      memory                  = optional(number),
      name                    = string,
      requiresCompatibilities = optional(string),
      publish = optional(object(
        {
          containerPort       = number,
          containerProtocol   = string,
          containerIpProtocol = string,
          lbhc_path           = string,
          lbhc_port           = number,
          lbhc_protocol       = string,
          lbPort              = number,
          lbProtocol          = string,
          lbIpProtocol        = string
        }
      ), null),
      secrets = optional(list(object({
        name      = string,
        valueFrom = string
      }))),
      environment = optional(list(object(
        {
          name  = string,
          value = string
        }
      )))
      entryPoint = optional(list(string)),
      command    = optional(list(string)),
      mountPoints = optional(list(object(
        {
          sourceVolume  = string,
          containerPath = string,
          readOnly      = bool
        }
      ))),
      portMappings = optional(list(object(
        {
          containerPort = number,
          protocol      = string
        }
      ))),
      essential = optional(bool),
      linuxParameters = optional(object(
        {
          initProcessEnabled = optional(bool)
        }
      ))
    }
  ))
}

# Monitoring Variables
# List of actions to trigger when alerts are sent
variable "alert_actions" {
  description = "List of ARN of action to take on alarms, e.g. SNS topics"
  type        = list(any)
  default     = []
}

# CPU Alert Threshold
variable "cpu_alert_threshold" {
  description = "Threshold which will trigger a alert when the cpu crosses"
  default     = "80"
}

# Memory Alert Threshold
variable "memory_alert_threshold" {
  description = "Threshold which will trigger a alert when the memory crosses"
  default     = "80"
}

variable "monitor_path" {
  description = "The route ('/', '/hlthchk', etc) to monitor for the website"
  type        = string
  default     = "/"
}

variable "monitor" {
  description = "true will create a LogicMonitor website monitor"
  type        = bool
  default     = false
}
