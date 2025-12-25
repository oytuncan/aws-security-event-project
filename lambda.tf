# 1. Python dosyasını ZIP haline getir (AWS Lambda ZIP ister)
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/security_handler.py"
  output_path = "${path.module}/lambda/security_payload.zip"
}

# 2. Lambda Fonksiyonunu Oluştur
resource "aws_lambda_function" "security_processor" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "${var.project_name}-processor"
  role          = aws_iam_role.lambda_role.arn
  handler       = "security_handler.lambda_handler" # DosyaAdı.FonksiyonAdı
  runtime       = "python3.9"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

output "lambda_name" {
  value = aws_lambda_function.security_processor.function_name
}