# 🔄 CI/CD Pipeline – Flutter Android

## 1. Mục tiêu
- Đảm bảo code không lỗi trước khi merge
- Tự động build APK Android
- Không để secrets trong repository

## 2. CI Workflow
- Trigger: Pull Request vào `main`
- Các bước:
  - flutter pub get
  - flutter analyze
  - flutter test

## 3. CD Workflow
- Trigger: push vào `main`
- Các bước:
  - Inject google-services.json từ Secrets
  - flutter build apk --debug
  - Upload APK artifact

## 4. Secrets sử dụng
| Name | Mô tả |
|----|------|
| GOOGLE_SERVICES_JSON | Firebase Android config |

## 5. Version Pinning
- Flutter: 3.38.8
- Kotlin: 2.1.0
- Android Gradle Plugin: 8.9.1
- Gradle: 8.11.1

## 6. Checklist ổn định
- CI pass ≥ 5 lần
- Không push trực tiếp main
- APK cài được
- Secrets không commit
