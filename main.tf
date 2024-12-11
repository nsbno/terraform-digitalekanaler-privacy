

data "aws_sns_topic" "privacy_sns" {
  name = "privacy-requests"
}


module "queue" {
  source = "github.com/nsbno/terraform-aws-queue?ref=0.0.5"

  name                 = "${var.application_name}-privacy-requests"
  is_fifo              = false
  raw_message_delivery = true
  visibility_timeout   = 30
  subscribe_sns_arns   = [data.aws_sns_topic.privacy_sns.arn]

  filter_policy = jsonencode(
    {
      "$or" : [
        {
          "service" : [
            var.privacy_service_enum
          ],
          "requestType" : [
            "INSIGHT"
          ]
        },
        {
          "requestType" : [
            "DELETE"
          ]
        }
      ]
    }
  )
}

data "aws_sns_topic" "privacy_audit" {
  name = "privacy-confirmations"
}

data "aws_iam_policy_document" "privacy_iam_policy_document" {
  statement {
    actions = [
      "SQS:ReceiveMessage",
      "SQS:DeleteMessage",
      "sqs:getqueueattributes"
    ]
    effect = "Allow"

    resources = [
      module.queue.queue_arn,
    ]
  }
  statement {
    actions = [
      "SNS:Publish",
    ]
    effect = "Allow"

    resources = [
      data.aws_sns_topic.privacy_audit.arn,
    ]
  }
}

resource "aws_iam_policy" "privacy_iam_policy" {
  name        = "${var.application_name}-privacy-iam-policy"
  path        = "/"
  description = "Grants read and delete access to privacy-queues configured in ${var.application_name}"
  policy      = data.aws_iam_policy_document.privacy_iam_policy_document.json
}

resource "aws_iam_role_policy_attachment" "privacy_policy_attachment" {
  role       = var.task_role_name
  policy_arn = aws_iam_policy.privacy_iam_policy.arn
}

data "aws_kms_key" "user_data_encryption_key" {
  key_id = "arn:aws:kms:eu-west-1:${var.current_account_id}:alias/user_data_v2_s3_encryption_key"
}

data "aws_s3_bucket" "privacy_bucket" {
  bucket = "${var.current_account_id}-user-data-v2"
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    actions = [
      "s3:PutObject"
    ]
    effect = "Allow"

    resources = [
      "${data.aws_s3_bucket.privacy_bucket.arn}/**/${var.privacy_service_enum}.json"
    ]
  }
  statement {
    actions   = ["kms:GenerateDataKey"]
    resources = [data.aws_kms_key.user_data_encryption_key.arn]
  }
}

resource "aws_iam_policy" "s3_iam_policy" {
  name = "${var.application_name}-s3-iam-policy"
  path = "/"
  description = "Grants access to put object in privacy-bucket"
  policy = data.aws_iam_policy_document.s3_access.json
}

resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  policy_arn = aws_iam_policy.s3_iam_policy.arn
  role       = var.task_role_name
}