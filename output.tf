
output "sqs_queue_url" {
  value = module.queue.queue_url
}

output "sns_privacy_audit_arn" {
  value = data.aws_sns_topic.privacy_audit.arn
}
