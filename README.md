# AWS Event-Driven Security Automation 🛡️

Bu proje, AWS üzerinde siber güvenlik olaylarını (Security Incidents) otomatik olarak yakalayan, analiz eden ve bildiren olay güdümlü (event-driven) bir mimaridir.

## 🏗️ Mimari
Proje Terraform kullanılarak (IaC) geliştirilmiştir ve şu servisleri içerir:
- **AWS EventBridge:** Olayları filtreleyen ve yönlendiren merkez.
- **API Gateway:** Dış dünyadan (Webhook) güvenli veri alımı (Lambda-less integration).
- **AWS Lambda (Python):** Olay verilerini işleyen ve loglayan işlemci.
- **Amazon SNS:** Kritik olaylarda yöneticiye e-mail/SMS bildirimi.
- **IAM:** "Least Privilege" prensibine uygun yetkilendirme.

## 🚀 Kurulum

1. Repoyu klonlayın:
   ```bash
   git clone [https://github.com/oytuncan/aws-security-event-project.git](https://github.com/oytuncan/aws-security-event-project.git)