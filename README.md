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
