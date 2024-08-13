locals {
  short_name   = var.json.short_name
  name         = "${lower(var.namespace)}-${lower(var.json.short_name)}"
  project_name = "${var.namespace}-${var.json.project_name}"
}
