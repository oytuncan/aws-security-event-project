import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    # EventBridge'den gelen sinyali ekrana (CloudWatch Logs) basar
    logger.info("Guvenlik Sinyali Alindi: %s", json.dumps(event))
    
    # Burada ileride veriyi analiz eden kodlar olacak
    detail = event.get('detail', {})
    severity = detail.get('severity', 'UNKNOWN')
    
    return {
        'statusCode': 200,
        'body': json.dumps(f"Olay islendi. Seviye: {severity}")
    }