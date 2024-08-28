variable "namespace" {
  default     = "pr"
  description = "Name used for prefix to differentiate resources."
}

variable "function_name" {
  description = "A unique name for your Lambda Function."
}

variable "function_arn" {
  description = "ARN for your Lambda Function."
}

variable "tags" {
  default     = {}
  description = "A mapping of tags to assign to the object."
}

variable "enable" {
  description = "Conditionally enables this module (and all it's ressources)."
  type        = bool
  default     = false
}