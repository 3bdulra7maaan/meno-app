# Meno

**اسأل زول جرّب** — تطبيق أسئلة وأجوبة بسيط للمجتمع السوداني، مبني بـ Flutter ومصمم لأندرويد أولاً.

## MVP

- تصفح الأسئلة المعتمدة بدون تسجيل دخول
- بحث وتصنيفات عربية
- إرسال سؤال للمراجعة مع خيار النشر كمجهول
- حالات moderation: `pending`, `approved`, `rejected`
- تفاصيل السؤال، إضافة إجابات، وتصويت «أفادني»
- واجهة RTL عربية وهوية كحلي وأصفر
- طبقة repository قابلة للتبديل بين بيانات تجريبية وSupabase

## التشغيل

ثبت Flutter stable ثم شغّل:

```bash
flutter create --platforms=android --org=com.meno.app .
flutter pub get
flutter run
```

بدون إعدادات إضافية يعمل التطبيق ببيانات تجريبية محلية. لاستخدام Supabase:

1. نفّذ [`supabase/schema.sql`](supabase/schema.sql) في Supabase SQL Editor.
2. شغّل التطبيق باستخدام مفاتيح العميل العامة فقط:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

لا تضع `service_role` key داخل التطبيق. عمليات الاعتماد أو الرفض تنفذ من لوحة إدارة آمنة تستخدم service role في الخادم.

## البناء

GitHub Actions يشغّل format/analyze/tests ويبني APK release، ثم يرفعه كـ workflow artifact باسم `meno-android-apk`.
