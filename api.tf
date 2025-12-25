# ---------------------------------------------------------
# 1. API Gateway için Yetki (Role) Tanımları
# ---------------------------------------------------------
# API Gateway'in EventBridge'e veri yazabilmesi için bir kimliğe ihtiyacı var.
resource "aws_iam_role" "api_gateway_role" {
  name = "${var.project_name}-api-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "api_gateway_eventbridge_policy" {
  name = "${var.project_name}-api-policy"
  role = aws_iam_role.api_gateway_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "events:PutEvents"
      Resource = aws_cloudwatch_event_bus.security_bus.arn
    }]
  })
}

# ---------------------------------------------------------
# 2. API Gateway Oluşturma (REST API)
# ---------------------------------------------------------
resource "aws_api_gateway_rest_api" "security_api" {
  name        = "${var.project_name}-public-api"
  description = "Dis dunyadan guvenlik olaylarini kabul eden kapi"
}

# Kaynak Oluşturma: /alerts (URL'in son kısmı)
resource "aws_api_gateway_resource" "alerts_resource" {
  rest_api_id = aws_api_gateway_rest_api.security_api.id
  parent_id   = aws_api_gateway_rest_api.security_api.root_resource_id
  path_part   = "alerts"
}

# Metot Oluşturma: POST (Sadece POST kabul et)
resource "aws_api_gateway_method" "post_alert" {
  rest_api_id   = aws_api_gateway_rest_api.security_api.id
  resource_id   = aws_api_gateway_resource.alerts_resource.id
  http_method   = "POST"
  authorization = "NONE" # Gerçek hayatta buraya API Key eklenir
}

# ---------------------------------------------------------
# 3. Entegrasyon: API Gateway -> EventBridge (Büyü Burada!)
# ---------------------------------------------------------
resource "aws_api_gateway_integration" "eventbridge_integration" {
  rest_api_id             = aws_api_gateway_rest_api.security_api.id
  resource_id             = aws_api_gateway_resource.alerts_resource.id
  http_method             = aws_api_gateway_method.post_alert.http_method
  integration_http_method = "POST"
  type                    = "AWS" # Bir AWS servisine bağlanıyoruz
  uri                     = "arn:aws:apigateway:${var.aws_region}:events:path//"
  credentials             = aws_iam_role.api_gateway_role.arn

  request_parameters = {
    "integration.request.header.X-Amz-Target" = "'AWSEvents.PutEvents'"
    "integration.request.header.Content-Type" = "'application/x-amz-json-1.1'"
  }

  # Mapping Template: Gelen basit JSON'ı EventBridge'in istediği formata çevirir
  request_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
{
  "Entries": [
    {
      "Source": "external.webhook",
      "DetailType": "External Security Alert",
      "Detail": "$util.escapeJavaScript($input.json('$'))",
      "EventBusName": "${aws_cloudwatch_event_bus.security_bus.name}"
    }
  ]
}
EOF
  }
}

# API Yanıtı (Başarılı olursa 200 dön)
resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.security_api.id
  resource_id = aws_api_gateway_resource.alerts_resource.id
  http_method = aws_api_gateway_method.post_alert.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.security_api.id
  resource_id = aws_api_gateway_resource.alerts_resource.id
  http_method = aws_api_gateway_method.post_alert.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code
  
  depends_on = [aws_api_gateway_integration.eventbridge_integration]
}

# ---------------------------------------------------------
# 4. Yayına Alma (Deployment)
# ---------------------------------------------------------
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.security_api.id
  
  # Terraform'un her değişiklikte yeniden deploy etmesi için bir tetikleyici
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.alerts_resource.id,
      aws_api_gateway_method.post_alert.id,
      aws_api_gateway_integration.eventbridge_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod_stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.security_api.id
  stage_name    = "prod"
}