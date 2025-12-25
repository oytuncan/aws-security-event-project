# 1. Özel Event Bus Oluşturulması
resource "aws_cloudwatch_event_bus" "security_bus" {
  name = "${var.project_name}-bus"
}

# 2. Event Bus için Log Grubu (Opsiyonel ama debug için hayat kurtarır)
resource "aws_cloudwatch_log_group" "event_logs" {
  name              = "/aws/events/${var.project_name}"
  retention_in_days = 1
}