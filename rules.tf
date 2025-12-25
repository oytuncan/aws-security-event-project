# ---------------------------------------------------------
# 1. KURAL: Kritik Olaylar (CRITICAL)
# ---------------------------------------------------------
resource "aws_cloudwatch_event_rule" "critical_rule" {
  name           = "${var.project_name}-critical-rule"
  description    = "Yüksek önem dereceli olayları yakalar"
  event_bus_name = aws_cloudwatch_event_bus.security_bus.name

  # İşte filtreleme sihirbazlığı burada (Event Pattern)
  event_pattern = jsonencode({
    detail = {
      severity = ["CRITICAL"]
    }
  })
}

# ---------------------------------------------------------
# 2. HEDEFLER: Bu kural tetiklenince ne olsun?
# ---------------------------------------------------------

# Hedef A: Lambda Fonksiyonunu Çalıştır
resource "aws_cloudwatch_event_target" "target_lambda" {
  rule           = aws_cloudwatch_event_rule.critical_rule.name
  event_bus_name = aws_cloudwatch_event_bus.security_bus.name
  target_id      = "SendToLambda"
  arn            = aws_lambda_function.security_processor.arn
}

# Hedef B: SNS ile Mail/SMS Gönder
resource "aws_cloudwatch_event_target" "target_sns" {
  rule           = aws_cloudwatch_event_rule.critical_rule.name
  event_bus_name = aws_cloudwatch_event_bus.security_bus.name
  target_id      = "SendToSNS"
  arn            = aws_sns_topic.security_alerts.arn
  
  # Mailin içeriğini güzelleştirmek için (Opsiyonel)
  input_transformer {
    input_paths = {
      source = "$.source",
      detail = "$.detail"
    }
    input_template = "\"DIKKAT! <source> kaynagindan KRITIK seviyede bir olay geldi. Detaylar: <detail>\""
  }
}

# ---------------------------------------------------------
# 3. İZİNLER: EventBridge'in diğerlerine erişmesi için izinler
# ---------------------------------------------------------

# İzin A: EventBridge -> Lambda'yı tetikleyebilsin
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.security_processor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.critical_rule.arn
}

# İzin B: EventBridge -> SNS'e mesaj atabilsin
resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.security_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.security_alerts.arn
      }
    ]
  })
}