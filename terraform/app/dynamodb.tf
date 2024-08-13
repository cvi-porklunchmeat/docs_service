module "tfm_aws_dynamodb" {
  source                             = "git::https://github.com/cloud-investors/tfm_aws_dynamodb?ref=v0.0.1"
  name                               = local.project_name
  hash_key                           = "user_email"
  range_key                          = "doc_id"
  table_class                        = "STANDARD"
  billing_mode                       = "PROVISIONED"
  point_in_time_recovery_enabled     = true
  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = aws_kms_key.dynamodb_kms.arn

  read_capacity               = 20
  write_capacity              = 20
  deletion_protection_enabled = lower(var.namespace) == "prod" ? true : false

  attributes = [
    {
      name = "doc_id"
      type = "S"
    },
    {
      name = "doc_checksum"
      type = "S"
    },
    {
      name = "user_group"
      type = "S"
    },
    {
      name = "user_email"
      type = "S"
    }
  ]

  global_secondary_indexes = [
    {
      name               = "GroupIndex"
      hash_key           = "user_group"
      range_key          = "user_email"
      projection_type    = "INCLUDE"
      non_key_attributes = ["doc_id"]
      write_capacity     = 20
      read_capacity      = 20
    },
    {
      name               = "DocIndex"
      hash_key           = "doc_id"
      range_key          = "doc_checksum"
      projection_type    = "INCLUDE"
      non_key_attributes = ["create_date"]
      write_capacity     = 20
      read_capacity      = 20
    }
  ]
}
