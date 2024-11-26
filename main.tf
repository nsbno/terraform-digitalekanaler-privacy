

data "aws_sns_topic" "privacy_sns" {
  name = "privacy"
}


module "queue" {
  source = "github.com/nsbno/terraform-aws-queue?ref=0.0.5"

  name = "${var.application_name}-privacy"
  is_fifo = false
  raw_message_delivery = true
  visibility_timeout = 30
  subscribe_sns_arns = [data.aws_sns_topic.privacy_sns.arn]

  filter_policy = jsonencode(
    {
      "$or": [
        {
          "service": [
            var.privacy_service_enum
          ],
          "requestType": [
            "INSIGHT"
          ]
        },
        {
          "requestType": [
            "DELETE"
          ]
        }
      ]
    }
  )
}

data "aws_sns_topic" "privacy_audit" {
  name = "privacy-audit"
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
  description = "Grants read and delete access to sqs queues configured in ${var.application_name}"
  policy      = data.aws_iam_policy_document.privacy_iam_policy_document.json
}

resource "aws_iam_role_policy_attachment" "user_data_privacy_policy_attachment" {
  role       = var.task_role_name
  policy_arn = aws_iam_policy.privacy_iam_policy.arn
}