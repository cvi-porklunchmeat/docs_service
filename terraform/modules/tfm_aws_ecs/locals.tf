locals {
  timestamp  = timestamp()
  namespace  = lower(var.namespace)
  name       = "${local.namespace}-${lower(var.app_name)}"
  short_name = "${local.namespace}-${lower(var.app_short_name)}"
  # Convert JSON list of objects into HCL map of maps
  container_definitions = { for item in var.container_definitions :
    item.name => {
      name                = item.name
      lbPort              = item.publish != null ? item.publish.lbPort : ""
      lbProtocol          = item.publish != null ? upper(item.publish.lbProtocol) : ""
      lbIpProtocol        = item.publish != null ? upper(item.publish.lbIpProtocol) : ""
      containerPort       = item.publish != null ? item.publish.containerPort : ""
      containerProtocol   = item.publish != null ? upper(item.publish.containerProtocol) : ""
      containerIpProtocol = item.publish != null ? upper(item.publish.containerIpProtocol) : ""
      lbhc_port           = item.publish != null ? item.publish.lbhc_port : ""
      lbhc_protocol       = item.publish != null ? item.publish.lbhc_protocol : ""
      lbhc_path           = item.publish != null ? item.publish.lbhc_path : ""
    }
  }
  # Mapping of AWS account numbers used to s3:PutObject for ALB logs
  # https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html
  aws_access_log_accts = {
    us-east-1      = "127311923021",
    us-east-2      = "033677994240",
    us-west-1      = "027434742980",
    us-west-2      = "797873946194",
    af-south-1     = "098369216593",
    ap-east-1      = "754344448648",
    ap-southeast-3 = "589379963580",
    ap-south-1     = "718504428378",
    ap-northeast-3 = "383597477331",
    ap-northeast-2 = "600734575887",
    ap-southeast-1 = "114774131450",
    ap-southeast-2 = "783225319266",
    ap-northeast-1 = "582318560864",
    ca-central-1   = "985666609251",
    eu-central-1   = "054676820928",
    eu-west-1      = "156460612806",
    eu-west-2      = "652711504416",
    eu-south-1     = "635631232127",
    eu-west-3      = "009996457667",
    eu-north-1     = "897822967062",
    me-south-1     = "076674570225",
    sa-east-1      = "507241528517"
  }
}
