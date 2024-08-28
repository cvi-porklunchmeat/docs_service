<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 4.46.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | 4.0.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.46.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.0.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/resources/acm_certificate) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/resources/ecs_cluster) | resource |
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.exec_this](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/resources/iam_role) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.this](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/resources/kms_alias) | resource |
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/resources/kms_key) | resource |
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/resources/lb) | resource |
| [aws_lb_listener.this](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/resources/lb_listener) | resource |
| [aws_lb_listener.this_http](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/resources/lb_target_group) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/resources/s3_bucket) | resource |
| [aws_security_group.this_alb](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/resources/security_group) | resource |
| [aws_security_group.this_task](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/resources/security_group) | resource |
| [tls_private_key.this](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/private_key) | resource |
| [tls_self_signed_cert.this](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/self_signed_cert) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/4.46.0/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_sg"></a> [alb\_sg](#input\_alb\_sg) | n/a | `any` | n/a | yes |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | n/a | `string` | n/a | yes |
| <a name="input_cluster_cpu"></a> [cluster\_cpu](#input\_cluster\_cpu) | n/a | `string` | `"1024"` | no |
| <a name="input_cluster_ram"></a> [cluster\_ram](#input\_cluster\_ram) | n/a | `string` | `"2048"` | no |
| <a name="input_container_definitions"></a> [container\_definitions](#input\_container\_definitions) | n/a | <pre>list(object(<br>    {<br>      image  = string,<br>      cpu    = number,<br>      memory = number,<br>      name   = string,<br>      publish = optional(object(<br>        {<br>          containerPort       = number,<br>          containerProtocol   = string,<br>          containerIpProtocol = string,<br>          lbPort              = number,<br>          lbProtocol          = string,<br>          lbIpProtocol        = string<br>        }<br>      )),<br>      secrets = optional(list(object({<br>        name      = string,<br>        valueFrom = string<br>      }))),<br>      environment = optional(list(object(<br>        {<br>          name  = string,<br>          value = string<br>        }<br>      )))<br>      entryPoint = optional(list(string)),<br>      portMappings = list(object(<br>        {<br>          containerPort = number,<br>          protocol      = string<br>        }<br>      )),<br>      essential = optional(bool),<br>      linuxParameters = optional(object(<br>        {<br>          initProcessEnabled = optional(bool)<br>        }<br>      ))<br>    }<br>  ))</pre> | n/a | yes |
| <a name="input_health_check_grace_period"></a> [health\_check\_grace\_period](#input\_health\_check\_grace\_period) | n/a | `number` | `180` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Variables file for declaration/definition of variables used within the TF | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | n/a | `list(string)` | n/a | yes |
| <a name="input_task_sg"></a> [task\_sg](#input\_task\_sg) | n/a | `any` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecs_url"></a> [ecs\_url](#output\_ecs\_url) | n/a |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | n/a |
<!-- END_TF_DOCS -->

## Example Implementation Code

In order to use this module, there is a Logic Monitor component that needs to be passed in as a provider from the parent module code.  The following is an example of how to use this module:

```hcl
# LogicMonitor Provider config
data "aws_secretsmanager_secret_version" "lm_secret" {
  provider  = aws.management
  secret_id = var.lm_secret_name
}
provider "logicmonitor" {
  api_id  = jsondecode(data.aws_secretsmanager_secret_version.lm_secret.secret_string)["access_id"]
  api_key = jsondecode(data.aws_secretsmanager_secret_version.lm_secret.secret_string)["access_key"]
  company = jsondecode(data.aws_secretsmanager_secret_version.lm_secret.secret_string)["company"]
}

variable "lm_secret_name" {
  type        = string
  description = "The name of the LogicMonitor secret in AWS Secrets Manager"
  default     = "LogicMonitorAutomation"
}

module "tfm_aws_ecs" {
  source     = "git::https://github.com/cloud-investors/tfm_aws_ecs.git?ref=v6.1.1"
  depends_on = [docker_registry_image.this]
  namespace  = var.namespace
  providers = {
    aws.network  = aws.network,
    logicmonitor = logicmonitor,
  }

```
