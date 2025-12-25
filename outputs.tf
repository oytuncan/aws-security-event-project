output "event_bus_name" {
  description = "Oluşturulan Event Bus'ın adı"
  value       = aws_cloudwatch_event_bus.security_bus.name
}

output "event_bus_arn" {
  description = "Event Bus ARN (Amazon Resource Name)"
  value       = aws_cloudwatch_event_bus.security_bus.arn
}
output "api_url" {
  description = "Webhook URL adresimiz"
  value       = "${aws_api_gateway_stage.prod_stage.invoke_url}/alerts"
}