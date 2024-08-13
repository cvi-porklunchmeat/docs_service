output "api-url" {
  value = "https://${aws_api_gateway_rest_api.gateway_api.id}-${module.tfm_aws_network.vpce_outputs.execute-api.endpoints.execute-api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
}
