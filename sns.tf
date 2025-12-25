resource "aws_sns_topic" "security_alerts" {
  name = "${var.project_name}-critical-alerts"
}

output "sns_topic_arn" {
  description = "SNS Topic ARN"
  value       = aws_sns_topic.security_alerts.arn
}