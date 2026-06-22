# Hajez Flutter App (حاجز)

تطبيق Flutter لحجز المزارع والشاليهات - السوق الأردني.

## ⚠️ ملفات لم تُرفع لأسباب أمنية

الملفات التالية مستثناة من الريبو (موجودة في `.gitignore`) لأنها تحتوي على بيانات حساسة:

| الملف | الوصف | كيف تضيفه محلياً |
|---|---|---|
| `android/app/hajez-release.jks` | مفتاح توقيع تطبيق Android (Release) | احتفظ بنسخة منه في مكان آمن (مثل GitHub Secrets أو password manager)، وضعه يدوياً في هذا المسار قبل البناء |
| `android/key.properties` | كلمات سر مفتاح التوقيع | أنشئه يدوياً بالصيغة: `storePassword=...`<br>`keyPassword=...`<br>`keyAlias=...`<br>`storeFile=hajez-release.jks` |
| `android/app/google-services.json` | إعدادات Firebase | نزّله من Firebase Console → Project Settings → Android App |
| `keystore_b64.txt` | نسخة Base64 من المفتاح (لاستخدامها في GitHub Actions secrets) | احتفظ بها محلياً فقط، أو ضعها كـ GitHub Secret باسم `KEYSTORE_BASE64` |

## 🚀 GitHub Actions (بناء تلقائي)

يوجد workflow جاهز في `.github/workflows/android-build.yml` يبني APK + AAB موقّعين تلقائياً عند كل push على `main`، أو يدوياً من تبويب Actions.

### الإعداد المطلوب (مرة واحدة فقط)

روح لـ: **Settings → Secrets and variables → Actions → New repository secret** وأضف:

| اسم Secret | المحتوى |
|---|---|
| `GOOGLE_SERVICES_JSON_BASE64` | `base64 -w 0 google-services.json` (شغّلها محلياً على ملف Firebase وانسخ المخرج) |
| `KEYSTORE_BASE64` | `base64 -w 0 hajez-release.jks` |
| `KEY_STORE_PASSWORD` | كلمة سر الـ keystore |
| `KEY_PASSWORD` | كلمة سر الـ key alias |
| `KEY_ALIAS` | اسم الـ alias (مثلاً `hajez`) |

### تشغيل البناء

- **تلقائي:** أي push على `main` يبني نسخة Release APK.
- **يدوي:** تبويب **Actions → Android Build (APK) → Run workflow**.

الناتج (APK) يطلع كـ **Artifact** بنفس صفحة الـ run، تحت "Artifacts" بالأسفل.

## التشغيل

```bash
flutter pub get
flutter run
```

## البناء (Release APK/AAB)

تأكد من وجود `android/key.properties` و `android/app/hajez-release.jks` قبل البناء:

```bash
flutter build appbundle --release
```

## البنية

```
lib/
  main.dart
  providers/     # State management (Provider)
  services/      # API calls (Dio)
  screens/       # شاشات التطبيق
  widgets/       # عناصر واجهة قابلة لإعادة الاستخدام
  utils/         # الثيم والثوابت
```
