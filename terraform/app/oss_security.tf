resource "aws_opensearchserverless_security_policy" "network" {
  provider    = aws.data
  name        = "${var.namespace}-opensearch"
  type        = "network"
  description = "Limit access to OpenSearch"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection",
          Resource = [
            "collection/${aws_opensearchserverless_collection.opensearch.name}"
          ]
        },
        {
          ResourceType = "dashboard",
          Resource = [
            "collection/${aws_opensearchserverless_collection.opensearch.name}"
          ]
        }
      ],
      SourceVPCEs = [
        aws_opensearchserverless_vpc_endpoint.app.id
      ]
      AllowFromPublic = false
    }
  ])
}

resource "aws_opensearchserverless_security_policy" "encryption" {
  provider    = aws.data
  name        = "${var.namespace}-opensearch"
  type        = "encryption"
  description = "Opensearch encryption configuration"
  policy = jsonencode({
    "Rules" = [
      {
        "Resource" = [
          "collection/${var.namespace}-opensearch"
        ],
        "ResourceType" = "collection"
      }
    ],
    "AWSOwnedKey" = true
  })
}
