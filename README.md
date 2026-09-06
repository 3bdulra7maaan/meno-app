# Meno

**اسأل زول جرّب** — تطبيق أسئلة وأجوبة بسيط للمجتمع السوداني، مبني بـ Flutter ومصمم لأندرويد أولاً.

## Meno v1

- تصفح الأسئلة المعتمدة بدون تسجيل دخول
- بحث وتصنيفات عربية
- إرسال سؤال للمراجعة مع خيار النشر كمجهول
- حالات moderation: `pending`, `approved`, `rejected`
- تفاصيل السؤال، إضافة إجابات، وتصويت «أفادني»
- واجهة RTL عربية بخط Almarai المضمن وهوية أسود وذهبي وبيج
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

لا تضع مفاتيح خاصة داخل التطبيق. لوحة الإدارة تستخدم Supabase Auth وقائمة `admin_users` وسياسات RLS للمراجعة. لا تحتاج لوحة المتصفح إلى service-role.

## البناء

GitHub Actions يشغّل format/analyze/tests ويبني APK release، ثم يرفعه كـ workflow artifact باسم `meno-android-apk`.

## Release and deployment

See [release/README.md](release/README.md) for signing, package/version/SDK,
Play declarations, remaining policy gates and verification checklist.
`main` owns the app, `admin/`, official `docs/` website and deployment workflows.
The Pages workflow builds the site and `/admin/` together using only validated public Supabase configuration.
Set Pages source to GitHub Actions and allow main in the github-pages environment.

The Android workflow publishes `meno-test-apk`, `meno-unsigned-aab-not-for-upload`,
and `meno-final-screenshots`. Only **Signed Play bundle** uses upload-key secrets.
Never upload test-signed APKs or unsigned bundles to Play.

Live admin verification is an explicit manual workflow, not a test that silently writes to
production on every pull request. Schema changes require a separately reviewed migration;
never rerun the fresh-project schema against an existing database.
