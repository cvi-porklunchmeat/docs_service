# Variables file for declaration/definition of variables used within the TF
variable "json" {
  type = any
}

variable "namespace" {
  type = string
}

variable "env_name" {
  description = "The namespaced name of the environment, e.g. pr-1-app, prod-app"
  type        = string
}

variable "git_sha" {
  description = "The the current short git sha for the project, e.g. 7c7a7ec (git rev-parse --short HEAD)"
  type        = string
}

variable "reponame" {
  type = string
}

variable "mgmtacct" {
  type    = string
  default = "589122266145"
}

variable "deploy_bucket_key_arn" {
  type = string
}

variable "deploy_bucket_name" {
  type = string
}

variable "az_secret_name" {
  type        = string
  description = "The name of the LogicMonitor secret in AWS Secrets Manager"
  default     = "terraform_service_principal"
}
