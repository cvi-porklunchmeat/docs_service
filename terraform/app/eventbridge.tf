module "eventbridge" {
  source = "terraform-aws-modules/eventbridge/aws"

  bus_name                  = "${local.project_name}-event-bridge"
  create_schemas_discoverer = true

  #attach_tracing_policy = true

  rules = {
    start_textract = {
      description = "Send S3 .pdf Object Created events to Textract"
      event_pattern = jsonencode(
        {
          "source" : ["Pipe ${aws_pipes_pipe.sqs_to_eventbridge.id}"],
          "detail" : {
            "eventSource" : ["aws:sqs"],
            "eventSourceARN" : [aws_sqs_queue.sqs_to_pipe.arn],
            "body" : {
              "Records" : {
                "$or" : [
                  {
                    "eventName" : ["ObjectCreated:CompleteMultipartUpload"]
                  },
                  {
                    "eventName" : ["ObjectCreated:Put"]
                  }
                ],
                "s3" : {
                  "object" : {
                    "key" : [{
                      "suffix" : ".pdf"
                    }]
                  }
                }
              }
            }
          }
        }
      )
      enabled = true
    }
    retrieve_textract = {
      description = "Send Textract result to S3 as .txt"
      event_pattern = jsonencode(
        {
          "source" : ["Pipe ${aws_pipes_pipe.sqs_to_eventbridge.id}"],
          "detail" : {
            "eventSource" : ["aws:sqs"],
            "eventSourceARN" : [aws_sqs_queue.sqs_to_pipe.arn],
            "body" : {
              "Message" : {
                "Status" : ["SUCCEEDED"]
              }
            }
          }
        }
      )
      enabled = true
    }
    push_to_opensearch = {
      description = "Send S3 .txt Object Create Event to OpenSearch"
      event_pattern = jsonencode(
        {
          "source" : ["Pipe ${aws_pipes_pipe.sqs_to_eventbridge.id}"],
          "detail" : {
            "eventSource" : ["aws:sqs"],
            "eventSourceARN" : [aws_sqs_queue.sqs_to_pipe.arn],
            "body" : {
              "Records" : {
                "eventName" : ["ObjectCreated:Put"],
                "userIdentity" : {
                  "principalId" : [{
                    "suffix" : "docs-service-retrieve-textract"
                  }]
                }
                "s3" : {
                  "object" : {
                    "key" : [{
                      "suffix" : ".txt"
                    }]
                  }
                }
              }
            }
          }
        }
      )
      enabled = true
    }
    event_logging = {
      description = "Security: Log all events"
      event_pattern = jsonencode(
        {
          "account" : [data.aws_caller_identity.current.account_id]
        }
      )
      enabled = true
    }
  }

  targets = {
    start_textract = [
      {
        name            = "${var.namespace}-start-textract"
        arn             = module.start_textract_lambda_function.arn
        dead_letter_arn = aws_sqs_queue.start_textract_lambda_dl_queue.arn
      }
    ]
    retrieve_textract = [
      {
        name            = "${var.namespace}-retrieve-textract"
        arn             = module.retrieve_textract_lambda_function.arn
        dead_letter_arn = aws_sqs_queue.retrieve_textract_lambda_dl_queue.arn
      }
    ]
    push_to_opensearch = [
      {
        name            = "${var.namespace}-pust_to_opensearch"
        arn             = module.push_to_opensearch_function.arn
        dead_letter_arn = aws_sqs_queue.push_to_opensearch_dl_queue.arn
      }
    ]
    event_logging = [
      {
        name = "${var.namespace}-event-logging"
        arn  = aws_cloudwatch_log_group.eventbridge_events.arn
      }
    ]
  }

  ######################
  # Additional policies
  ######################

  attach_policy_json = true
  policy_json        = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "xray:GetSamplingStatisticSummaries"
      ],
      "Resource": ["*"]
    }
  ]
}
EOF

  attach_policy_jsons = true
  policy_jsons = [<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "xray:*"
      ],
      "Resource": ["*"]
    }
  ]
}
EOF
  ]
}
