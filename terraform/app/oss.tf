resource "aws_opensearchserverless_collection" "opensearch" {
  provider = aws.data
  name     = "${var.namespace}-opensearch"

  depends_on = [
    aws_opensearchserverless_security_policy.encryption
  ]
}
