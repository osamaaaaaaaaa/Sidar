# تجهيز نسخة iOS على الماك

فك ZIP في مجلد جديد؛ لا تدمجه فوق نسخة الماك القديمة التي تحتوي على SwiftPM أو Pods مولّدة.

من داخل مجلد المشروع:

```bash
bash scripts/build_appstore.sh
```

السكربت يثبت إصدارات Dart المسجلة في `pubspec.lock`، يولد إعدادات Flutter، يشغل CocoaPods، ثم ينشئ archive موقّع ويصدر IPA باستخدام حساب Xcode. لا يرفع التطبيق تلقائيًا. لا تحذف lockfile ولا تستخدم `pub upgrade` قبل البناء.

ينفذ السكربت `flutter clean` قبل البناء؛ لذلك لا يمكن لملفات Flutter assets القديمة، ومنها خط Apple المحذوف، البقاء داخل الـIPA الجديد.

يستخدم مصدر الحزم `https://pub.flutter-io.cn` المطابق لملف القفل الموجود، داخل عملية البناء فقط. يلزم وصول الماك لهذا المصدر ولـCocoaPods؛ تغييره إلى pub.dev يحتاج إعادة التحقق من ملف القفل.

يقلل السكربت تنزيلات CocoaPods المتزامنة إلى طلب واحد لتجنب عطل CDN المعروف في HTTP/2. إذا استمر العطل بعد إعادة المحاولة، أضف مؤقتًا في أول `ios/Podfile`: `source 'https://github.com/CocoaPods/Specs.git'` ثم أعد الأمر؛ هذا البديل ينزل فهرسًا كبيرًا في أول مرة فقط.

المتطلبات الموجودة على الماك: Flutter (تم اختبار Dart محليًا مع Flutter 3.38.4 / Dart 3.10.3)، Xcode كامل مع iOS SDK المقبول حاليًا لدى Apple، CocoaPods، وحساب Apple Developer مدفوع مسجل في Xcode مع صلاحية تسجيل `com.sidarai.app`. قبول رخصة Xcode وتنزيل مكوناته مطلوبان قبل أول بناء. لا يمكن إنشاء شهادة Apple أو اختيار حساب صاحب التطبيق من Windows.

إذا لم يجد السكربت فريقًا واحدًا في شهادات Keychain، أو عند وجود أكثر من فريق:

```bash
APPLE_TEAM_ID=ABCDEFGHIJ bash scripts/build_appstore.sh
```

استبدل المثال بمعرف فريقك الحقيقي. رقم الإصدار الحالي `1.0.0+1`. للرفع التالي استخدم رقم بناء أعلى من الموجود في App Store Connect:

```bash
BUILD_NUMBER=2 bash scripts/build_appstore.sh
```

يمكن الجمع بين المتغيرين، وتمرير `DART_DEFINES_FILE` لمسار JSON يحوي إعدادات Supabase العامة إذا أردت بيئة مختلفة. لا تضع service-role keys أو مفاتيح سرية داخل التطبيق.

النتيجة داخل `build/appstore/<timestamp>/ipa/` ومعها archive و`build.log` في المجلد الأب. ارفع IPA بواسطة Transporter، ثم اختبر TestFlight قبل إرسال المراجعة. يجب إنشاء سجل التطبيق في App Store Connect بالـBundle ID نفسه؛ ملكيته لم يتم التحقق منها من هنا.

## التغييرات

- إزالة اعتماديات Firebase غير المستخدمة فعليًا؛ التحليل وتسجيل الدخول يستخدمان Supabase. إعداد Firebase القديم محفوظ في `docs/legacy/firebase_options.dart.txt` للرجوع إليه.
- استخدام CocoaPods لهذه النسخة وإيقاف ترحيل SwiftPM على مستوى المشروع، دون تغيير إعداد Flutter العام. لا يتم طلب `firebase-ios-sdk` بعد إزالة الاعتماديات.
- توحيد الحد الأدنى إلى iOS 16، وتجهيز static frameworks وExportOptions للتوقيع التلقائي.
- تسجيل `com.sidarai.app` لمعالجة الروابط عبر app_links وإيقاف معالج Flutter المنافس.
- توليد كل أحجام أيقونات iOS من شعار سدر الموجود، بخلفية معتمة مناسبة لأيقونة المتجر.
- تفعيل delegate إشعارات iOS.
- إزالة تعريف ملفات SF Pro المملوكة لـApple من Flutter assets؛ لن تُضمّن في IPA القادم. واجهة اللغة الإنجليزية تستخدم Cormorant Garamond عبر `google_fonts`.

## ما لم يُحسم بعد قبل مراجعة المتجر

هذه حزمة مصدر مجهزة للبناء، وليست شهادة بأن التطبيق مقبول لدى Apple. بناء Xcode والتوقيع وتصدير IPA لا يمكن اختبارها على Windows.

1. بناءً على اختيار صاحب التطبيق، إصدار iPhone بدون شراء اشتراكات: تم إخفاء عروض الشراء ومدخل الاشتراكات وحظر إنشاء جلسة Stripe على iOS. صلاحيات الحسابات الحالية ونسخة Android لم تتغير. لو أردت تفعيل الشراء لاحقًا، يلزم إعداد منتجات Apple وربط In-App Purchase والتحقق على الخادم وفق قواعد المتجر والمنطقة.
2. يلزم رابط سياسة خصوصية منشور، وربطه داخل التطبيق واستكمال App Privacy في App Store Connect. التطبيق يعالج صورًا وبيانات ملف شخصي وصحية؛ يجب أن تعكس الإفصاحات معالجة Supabase ومزود الذكاء الاصطناعي الفعلية. الموافقة على إرسال البيانات للطرف الثالث تحتاج مراجعة قبل الإرسال.
3. يلزم التأكد من سياسات وإعدادات Supabase الإنتاجية، وظائف التحليل، حذف الحساب `delete_own_account`، وحماية التخزين. الاختبارات المحلية تستخدم محاكاة ولا تثبت عمل الخادم الإنتاجي.
4. رابط App Store الافتراضي في `app_config_service.dart` مثال؛ ضع رابط التطبيق الحقيقي في `platform_settings` تحت `mobile_app_config.ios_store_url` قبل تفعيل طلب تحديث المستخدمين.
5. استكمل رابط الدعم، لقطات الشاشة، بيانات العمر والتشفير، وحساب تجربة للمراجع عند الحاجة. اختبر الكاميرا والتحليل والتسجيل وحذف الحساب والإشعارات على iPhone فعلي.

المراجع: [Flutter iOS release](https://docs.flutter.dev/deployment/ios)، [Flutter SwiftPM](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers)، [Apple Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).

## تحقق محلي

نجحت 68 حالة اختبار Flutter بعد إزالة Firebase. التحليل الساكن أظهر 115 ملاحظة معلوماتية عن تنسيق وتسميات وواجهات deprecated، دون أخطاء أو تحذيرات. تم فحص تركيب Bash وملفات plist؛ لم يُنفذ بناء iOS على هذا الجهاز.

نجح أيضًا اختباران إضافيان للتحقق من منع طلب الدفع على iOS قبل الوصول للخادم، وبقاء سياسة Android كما هي.
