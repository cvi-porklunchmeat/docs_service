resource "aws_opensearchserverless_access_policy" "opensearch" {
  provider    = aws.data
  name        = "${var.namespace}-opensearch"
  type        = "data"
  description = "Limit access to Opensearch via users/roles/etc."
  policy = jsonencode([
    {
      "Rules" : [
        {
          "Resource" : [
            "collection/${aws_opensearchserverless_collection.opensearch.name}"
          ],
          "ResourceType" : "collection",
          "Permission" : [
            "aoss:CreateCollectionItems",
            "aoss:DeleteCollectionItems",
            "aoss:UpdateCollectionItems",
            "aoss:DescribeCollectionItems"
          ]
        },
        {
          "ResourceType" : "index",
          "Resource" : [
            "index/${aws_opensearchserverless_collection.opensearch.name}/*"
          ],
          "Permission" : [
            "aoss:CreateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:UpdateIndex",
            "aoss:DeleteIndex",
            "aoss:WriteDocument",
          ]
        }
      ],
      "Principal" : [aws_iam_role.doc_search_app_access.arn]
    }
  ])
}
