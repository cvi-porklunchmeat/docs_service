############################### Datum ###############################
data "logicmonitor_collector" "collector" {
  filter = "hostname~\"cloud*\""
}


############################### Resources ###############################
resource "logicmonitor_website" "synthetic" {
  count                      = var.monitor == true ? 1 : 0
  description                = "Monitor ${var.app_name} site response times"
  disable_alerting           = false
  domain                     = local.fqdn
  global_sm_alert_cond       = 0
  group_id                   = 1
  host                       = "https://${local.fqdn}${var.monitor_path}"
  individual_alert_level     = "warn"
  individual_sm_alert_enable = false
  is_internal                = true
  name                       = "${var.namespace}-${var.app_name}"
  overall_alert_level        = "warn"
  polling_interval           = 5
  steps = [
    {
      schema             = "https"
      resp_type          = "config"
      timeout            = 0
      match_type         = "plain"
      description        = "string"
      use_default_root   = true
      http_method        = "GET"
      enable             = true
      http_version       = "1.1"
      follow_redirection = true
      name               = "string"
      req_type           = "config"
      fullpage_load      = true
      require_auth       = false
      path               = "string"
      keyword            = "DEVWRT-SANRT-JOB1-9127"
      http_body          = "string"
      resp_script        = "string"
      req_script         = "string"
      label              = "string"
      url                = "/"
      type               = "string"
      invert_match       = false
      status_code        = "200"
      auth = [{
        password  = "string"
        type      = "basic"
        domain    = "string"
        user_name = "string"
      }]
      http_headers        = "X-Version:3"
      post_data_edit_type = "raw"
    }
  ]
  stop_monitoring              = false
  transition                   = 1
  type                         = "webcheck"
  use_default_alert_setting    = true
  use_default_location_setting = true
  user_permission              = "read"
}
