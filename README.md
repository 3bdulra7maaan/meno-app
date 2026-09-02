# Meno

**اسأل زول جرّب** — تطبيق أسئلة وأجوبة بسيط للمجتمع السوداني، مبني بـ Flutter ومصمم لأندرويد أولاً.

## MVP

- تصفح الأسئلة المعتمدة بدون تسجيل دخول
- بحث وتصنيفات عربية
- إرسال سؤال للمراجعة مع خيار النشر كمجهول
- حالات moderation: `pending`, `approved`, `rejected`
- تفاصيل السؤال، إضافة إجابات، وتصويت «أفادني»
- واجهة RTL عربية وهوية كحلي وأصفر
- اتصال فعلي بـ Supabase للأسئلة والإجابات والمراجعة وتصويت «أفادني»
- تصفح عام بدون دخول، مع جلسة Supabase مجهولة تُنشأ فقط عند أول كتابة

## التشغيل

ثبت Flutter stable ثم شغّل:

```bash
flutter create --platforms=android --org=com.meno.app .
flutter pub get
flutter run
```

بدون إعدادات إضافية يعمل التطبيق ببيانات تجريبية محلية. لاستخدام Supabase:

اتبع قائمة الإعداد الدقيقة في [`supabase/SETUP.md`](supabase/SETUP.md). باختصار:

1. نفّذ [`supabase/schema.sql`](supabase/schema.sql) في Supabase SQL Editor.
2. فعّل Anonymous Sign-Ins في Supabase Authentication.
3. شغّل التطبيق باستخدام Project URL وPublishable key العامة فقط:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
```

لا تضع `service_role` key داخل التطبيق. عمليات الاعتماد أو الرفض تنفذ من لوحة إدارة آمنة تستخدم service role في الخادم.

## البناء

GitHub Actions يشغّل format/analyze/tests ويبني APK release، ثم يرفعه كـ workflow artifact باسم `meno-android-apk`.
