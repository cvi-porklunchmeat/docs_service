variable "json" {
  type = any
}

variable "namespace" {
  description = "Naming for resources to separate concerns"
  type        = string
}

variable "env_name" {
  description = "The namespaced name of the environment, e.g. pr-1-app, prod-app"
  type        = string
}

variable "bucketname" {
  description = "Name for bucket created, concatenated to namespace"
  type        = string
}

variable "backendacct" {
  type    = string
  default = "589122266145"
}

variable "tags" {
  default     = {}
  description = "A mapping of tags to assign to the object."
}

variable "region" {
  type = string
}
