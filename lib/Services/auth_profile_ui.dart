import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skincare/Services/app_feedback.dart';
import 'package:skincare/Services/auth_service.dart';
import 'package:skincare/Services/profile_values.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';
import 'package:skincare/Views/Auth/Login.dart';
import 'package:skincare/Views/Home/Home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String authText(String en, String ar) =>
    Get.locale?.languageCode == 'ar' ? ar : en;

String profileLabel(String value) => switch (value) {
  'male' => authText('Male', 'ذكر'),
  'female' => authText('Female', 'أنثى'),
  'other' => authText('Other', 'آخر'),
  'normal' => authText('Normal', 'عادية'),
  'dry' => authText('Dry', 'جافة'),
  'oily' => authText('Oily', 'دهنية'),
  'combination' => authText('Combination', 'مختلطة'),
  'sensitive' => authText('Sensitive', 'حساسة'),
  'unknown' => authText("I don't know", 'لا أعرف'),
  _ => value,
};

String profileValidationMessage(String error) => switch (error) {
  'name' => authText('Please enter your name.', 'يرجى إدخال الاسم.'),
  'age' => authText(
    'Age must be a whole number from 1 to 120.',
    'العمر يجب أن يكون عددًا صحيحًا من 1 إلى 120.',
  ),
  'gender' => authText(
    'Please select a valid gender.',
    'يرجى اختيار الجنس من القائمة.',
  ),
  'skin' => authText('Please select skin type.', 'يرجى اختيار نوع البشرة.'),
  _ => authText('Please select country.', 'يرجى اختيار الدولة.'),
};

void authNotice(String message, {bool error = false}) {
  if (error) {
    AppFeedback.error(
      message,
      title: authText('Unable to complete', 'تعذر إكمال العملية'),
    );
  } else {
    AppFeedback.success(message, title: authText('SIDAR', 'سِدار'));
  }
}

Widget profileDropdown({
  required List<String> values,
  required String? value,
  required ValueChanged<String?> onChanged,
  bool requiredValue = false,
  bool country = false,
}) => DropdownButtonFormField<String>(
  initialValue: values.contains(value) ? value : null,
  isExpanded: true,
  dropdownColor: AppColors.surface,
  style: AppTheme.bodyStyle(),
  decoration: AppTheme.inputDecoration(hintText: authText('Select', 'اختر')),
  items: [
    if (!requiredValue)
      DropdownMenuItem(
        value: '',
        child: Text(authText('Not specified', 'غير محدد')),
      ),
    ...values.map(
      (code) => DropdownMenuItem(
        value: code,
        child: Text(
          country ? countryLabel(code) : profileLabel(code),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  ],
  validator: requiredValue
      ? (v) => v == null || v.isEmpty ? authText('Required', 'مطلوب') : null
      : null,
  onChanged: onChanged,
);

String countryLabel(String code) {
  final names = countryNames[code];
  return names == null ? code : authText(names.$1, names.$2);
}

// Country codes, not display names, are submitted to profiles.location_text.
const countryNames = <String, (String, String)>{
  // Arab and Middle East Countries
  'SA': ('Saudi Arabia', 'المملكة العربية السعودية'),
  'AE': ('United Arab Emirates', 'الإمارات العربية المتحدة'),
  'EG': ('Egypt', 'جمهورية مصر العربية'),
  'KW': ('Kuwait', 'الكويت'),
  'QA': ('Qatar', 'قطر'),
  'BH': ('Bahrain', 'البحرين'),
  'OM': ('Oman', 'سلطنة عُمان'),
  'JO': ('Jordan', 'الأردن'),
  'IQ': ('Iraq', 'العراق'),
  'MA': ('Morocco', 'المغرب'),
  'DZ': ('Algeria', 'الجزائر'),
  'TN': ('Tunisia', 'تونس'),
  'LB': ('Lebanon', 'لبنان'),
  'SD': ('Sudan', 'السودان'),
  'LY': ('Libya', 'ليبيا'),
  'YE': ('Yemen', 'اليمن'),
  'SY': ('Syria', 'سوريا'),
  'PS': ('Palestine', 'فلسطين'),
  'DJ': ('Djibouti', 'جيبوتي'),
  'SO': ('Somalia', 'الصومال'),
  'MR': ('Mauritania', 'موريتانيا'),
  'KM': ('Comoros', 'جزر القمر'),

  // Major Global & European Countries
  'GB': ('United Kingdom', 'المملكة المتحدة'),
  'US': ('United States', 'الولايات المتحدة الأمريكية'),
  'TR': ('Türkiye', 'تركيا'),
  'DE': ('Germany', 'ألمانيا'),
  'FR': ('France', 'فرنسا'),
  'IT': ('Italy', 'إيطاليا'),
  'ES': ('Spain', 'إسبانيا'),
  'CA': ('Canada', 'كندا'),
  'RU': ('Russia', 'روسيا'),
  'CN': ('China', 'الصين'),
  'JP': ('Japan', 'اليابان'),
  'KR': ('South Korea', 'كوريا الجنوبية'),
  'IN': ('India', 'الهند'),
  'BR': ('Brazil', 'البرازيل'),
  'AU': ('Australia', 'أستراليا'),
  'CH': ('Switzerland', 'سويسرا'),
  'SE': ('Sweden', 'السويد'),
  'NO': ('Norway', 'النرويج'),
  'NL': ('Netherlands', 'هولندا'),
  'BE': ('Belgium', 'بلجيكا'),
  'AT': ('Austria', 'النمسا'),
  'GR': ('Greece', 'اليونان'),
  'PT': ('Portugal', 'البرتغال'),
  'PL': ('Poland', 'بولندا'),
  'DK': ('Denmark', 'الدنمارك'),
  'FI': ('Finland', 'فنلندا'),
  'IE': ('Ireland', 'أيرلندا'),
  'NZ': ('New Zealand', 'نيوزيلندا'),
  'MY': ('Malaysia', 'ماليزيا'),
  'SG': ('Singapore', 'سنغافورة'),
  'ID': ('Indonesia', 'إندونيسيا'),
  'PK': ('Pakistan', 'باكستان'),
  'BD': ('Bangladesh', 'بنغلاديش'),
  'TH': ('Thailand', 'تايلاند'),
  'VN': ('Vietnam', 'فيتنام'),
  'PH': ('Philippines', 'الفلبين'),
  'ZA': ('South Africa', 'جنوب أفريقيا'),

  // Worldwide Alphabetical Countries
  'AF': ('Afghanistan', 'أفغانستان'),
  'AL': ('Albania', 'ألبانيا'),
  'AD': ('Andorra', 'أندورا'),
  'AO': ('Angola', 'أنغولا'),
  'AG': ('Antigua and Barbuda', 'أنتيغوا وبربودا'),
  'AR': ('Argentina', 'الأرجنتين'),
  'AM': ('Armenia', 'أرمينيا'),
  'AZ': ('Azerbaijan', 'أذربيجان'),
  'BS': ('Bahamas', 'البهاما'),
  'BB': ('Barbados', 'باربادوس'),
  'BY': ('Belarus', 'بيلاروسيا'),
  'BZ': ('Belize', 'بليز'),
  'BJ': ('Benin', 'بنين'),
  'BT': ('Bhutan', 'بوتان'),
  'BO': ('Bolivia', 'بوليفيا'),
  'BA': ('Bosnia and Herzegovina', 'البوسنة والهرسك'),
  'BW': ('Botswana', 'بوتسوانا'),
  'BN': ('Brunei', 'بروناي'),
  'BG': ('Bulgaria', 'بلغاريا'),
  'BF': ('Burkina Faso', 'بوركينا فاسو'),
  'BI': ('Burundi', 'بوروندي'),
  'CV': ('Cabo Verde', 'الرأس الأخضر'),
  'KH': ('Cambodia', 'كمبوديا'),
  'CM': ('Cameroon', 'الكاميرون'),
  'CF': ('Central African Republic', 'جمهورية أفريقيا الوسطى'),
  'TD': ('Chad', 'تشاد'),
  'CL': ('Chile', 'تشيلي'),
  'CO': ('Colombia', 'كولومبيا'),
  'CG': ('Congo', 'الكونغو'),
  'CD': ('DR Congo', 'جمهورية الكونغو الديمقراطية'),
  'CR': ('Costa Rica', 'كوستاريكا'),
  'CI': ("Côte d'Ivoire", 'ساحل العاج'),
  'HR': ('Croatia', 'كرواتيا'),
  'CU': ('Cuba', 'كوبا'),
  'CY': ('Cyprus', 'قبرص'),
  'CZ': ('Czech Republic', 'التشيك'),
  'DM': ('Dominica', 'دومينيكا'),
  'DO': ('Dominican Republic', 'جمهورية الدومينيكان'),
  'EC': ('Ecuador', 'الإكوادور'),
  'SV': ('El Salvador', 'السلفادور'),
  'GQ': ('Equatorial Guinea', 'غينيا الاستوائية'),
  'ER': ('Eritrea', 'إريتريا'),
  'EE': ('Estonia', 'إستونيا'),
  'SZ': ('Eswatini', 'إسواتيني'),
  'ET': ('Ethiopia', 'إثيوبيا'),
  'FJ': ('Fiji', 'فيجي'),
  'GA': ('Gabon', 'الغابون'),
  'GM': ('Gambia', 'غامبيا'),
  'GE': ('Georgia', 'جورجيا'),
  'GH': ('Ghana', 'غانا'),
  'GD': ('Grenada', 'غرينادا'),
  'GT': ('Guatemala', 'غواتيمالا'),
  'GN': ('Guinea', 'غينيا'),
  'GW': ('Guinea-Bissau', 'غينيا بيساو'),
  'GY': ('Guyana', 'غيانا'),
  'HT': ('Haiti', 'هايتي'),
  'HN': ('Honduras', 'هندوراس'),
  'HU': ('Hungary', 'المجر'),
  'IS': ('Iceland', 'آيسلندا'),
  'IR': ('Iran', 'إيران'),
  'IL': ('Israel', 'إسرائيل'),
  'JM': ('Jamaica', 'جامايكا'),
  'KZ': ('Kazakhstan', 'كازاخستان'),
  'KE': ('Kenya', 'كينيا'),
  'KI': ('Kiribati', 'كيريباتي'),
  'KG': ('Kyrgyzstan', 'قيرغيزستان'),
  'LA': ('Laos', 'لاوس'),
  'LV': ('Latvia', 'لاتفيا'),
  'LS': ('Lesotho', 'ليسوتو'),
  'LR': ('Liberia', 'ليبيريا'),
  'LI': ('Liechtenstein', 'ليختنشتاين'),
  'LT': ('Lithuania', 'ليتوانيا'),
  'LU': ('Luxembourg', 'لوكسمبورغ'),
  'MG': ('Madagascar', 'مدغشقر'),
  'MW': ('Malawi', 'مالاوي'),
  'MV': ('Maldives', 'المالديف'),
  'ML': ('Mali', 'مالي'),
  'MT': ('Malta', 'مالطا'),
  'MH': ('Marshall Islands', 'جزر مارشال'),
  'MU': ('Mauritius', 'موريشيوس'),
  'MX': ('Mexico', 'المكسيك'),
  'FM': ('Micronesia', 'ميكرونيزيا'),
  'MD': ('Moldova', 'مولدوفا'),
  'MC': ('Monaco', 'موناكو'),
  'MN': ('Mongolia', 'منغوليا'),
  'ME': ('Montenegro', 'الجبل الأسود'),
  'MZ': ('Mozambique', 'موزمبيق'),
  'MM': ('Myanmar', 'ميانمار'),
  'NA': ('Namibia', 'ناميبيا'),
  'NR': ('Nauru', 'ناورو'),
  'NP': ('Nepal', 'نيبال'),
  'NI': ('Nicaragua', 'نيكاراغوا'),
  'NE': ('Niger', 'النيجر'),
  'NG': ('Nigeria', 'نيجيريا'),
  'KP': ('North Korea', 'كوريا الشمالية'),
  'MK': ('North Macedonia', 'مقدونيا الشمالية'),
  'PW': ('Palau', 'بالاو'),
  'PA': ('Panama', 'بنما'),
  'PG': ('Papua New Guinea', 'بابوا غينيا الجديدة'),
  'PY': ('Paraguay', 'باراغواي'),
  'PE': ('Peru', 'بيرو'),
  'RO': ('Romania', 'رومانيا'),
  'RW': ('Rwanda', 'رواندا'),
  'KN': ('Saint Kitts and Nevis', 'سانت كيتس ونيفيس'),
  'LC': ('Saint Lucia', 'سانت لوسيا'),
  'VC': ('Saint Vincent', 'سانت فنسنت والغرينادين'),
  'WS': ('Samoa', 'ساموا'),
  'SM': ('San Marino', 'سان مارينو'),
  'ST': ('Sao Tome and Principe', 'ساو تومي وبرينسيب'),
  'SN': ('Senegal', 'السنغال'),
  'RS': ('Serbia', 'صربيا'),
  'SC': ('Seychelles', 'سيشل'),
  'SL': ('Sierra Leone', 'سيراليون'),
  'SK': ('Slovakia', 'سلوفاكيا'),
  'SI': ('Slovenia', 'سلوفينيا'),
  'SB': ('Solomon Islands', 'جزر سليمان'),
  'SS': ('South Sudan', 'جنوب السودان'),
  'LK': ('Sri Lanka', 'سريلانكا'),
  'SR': ('Suriname', 'سورينام'),
  'TJ': ('Tajikistan', 'طاجيكستان'),
  'TZ': ('Tanzania', 'تنزانيا'),
  'TL': ('Timor-Leste', 'تيمور الشرقية'),
  'TG': ('Togo', 'توغو'),
  'TO': ('Tonga', 'تونغا'),
  'TT': ('Trinidad and Tobago', 'ترينيداد وتوباغو'),
  'TM': ('Turkmenistan', 'تركمانستان'),
  'TV': ('Tuvalu', 'توفالو'),
  'UG': ('Uganda', 'أوغندا'),
  'UA': ('Ukraine', 'أوكرانيا'),
  'UY': ('Uruguay', 'أوروغواي'),
  'UZ': ('Uzbekistan', 'أوزبكستان'),
  'VU': ('Vanuatu', 'فانواتو'),
  'VA': ('Vatican City', 'الفاتيكان'),
  'VE': ('Venezuela', 'فنزويلا'),
  'ZM': ('Zambia', 'زامبيا'),
  'ZW': ('Zimbabwe', 'زيمبابوي'),
};

/// One application-lifetime recovery listener, rather than listeners on routes
/// that disappear after login. Get.reset/onClose cancels both subscriptions.
class AuthFlow extends GetxService {
  static AuthFlow get instance =>
      Get.isRegistered<AuthFlow>() ? Get.find<AuthFlow>() : Get.put(AuthFlow());
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<Uri>? _linkSubscription;
  bool recoveryPending = false;
  bool _recoveryRouteOpen = false;
  bool _closed = false;
  late final Future<void> ready;

  @override
  void onInit() {
    super.onInit();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (state) {
        if (state.event == AuthChangeEvent.passwordRecovery) {
          recoveryPending = true;
          _openRecovery();
        } else if (recoveryPending && state.session != null) {
          _openRecovery();
        }
      },
      onError: (Object _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_closed) {
            authNotice(
              authText(
                'The sign-in link is invalid or expired. Please request a new one.',
                'رابط تسجيل الدخول غير صالح أو منتهي الصلاحية. اطلب رابطًا جديدًا.',
              ),
              error: true,
            );
          }
        });
        WidgetsBinding.instance.ensureVisualUpdate();
      },
    );
    ready = _readInitialLink();
    if (!kIsWeb) {
      _linkSubscription = AppLinks().uriLinkStream.listen(
        _checkLink,
        onError: (Object _) {},
      );
    }
  }

  Future<void> _readInitialLink() async {
    if (kIsWeb) {
      _checkLink(Uri.base);
    } else {
      try {
        final uri = await AppLinks().getInitialLink().timeout(
          const Duration(seconds: 2),
        );
        if (uri != null && !_closed) _checkLink(uri);
      } catch (_) {
        /* Deep links are optional on unsupported platforms. */
      }
    }
  }

  void _checkLink(Uri uri) {
    Map<String, String> fragment = {};
    try {
      fragment = Uri.splitQueryString(uri.fragment);
    } catch (_) {}
    if (uri.queryParameters['type'] == 'recovery' ||
        fragment['type'] == 'recovery' ||
        uri.queryParameters['auth_action'] == 'recovery') {
      recoveryPending = true;
      _openRecovery();
    }
  }

  void _openRecovery() {
    if (_closed ||
        _recoveryRouteOpen ||
        Supabase.instance.client.auth.currentSession == null)
      return;
    _recoveryRouteOpen = true;
    // Do not run Supabase work or route transitions inside its auth callback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_closed && recoveryPending)
        Get.offAll(() => const PasswordUpdateView(recovery: true));
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void finishRecovery() {
    recoveryPending = false;
    _recoveryRouteOpen = false;
  }

  @override
  void onClose() {
    _closed = true;
    _authSubscription?.cancel();
    _linkSubscription?.cancel();
    super.onClose();
  }
}

class PasswordUpdateView extends StatefulWidget {
  const PasswordUpdateView({super.key, this.recovery = false});
  final bool recovery;
  @override
  State<PasswordUpdateView> createState() => _PasswordUpdateViewState();
}

class _PasswordUpdateViewState extends State<PasswordUpdateView> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AuthService().updatePassword(_password.text, _confirmation.text);
      if (!mounted) return;
      if (widget.recovery) {
        await AuthService().prepareSession();
        if (!mounted) return;
        AuthFlow.instance.finishRecovery();
        Get.offAll(() => const HomeView());
      } else {
        Get.back();
      }
      authNotice(
        authText(
          'Password updated successfully.',
          'تم تغيير كلمة المرور بنجاح.',
        ),
      );
    } catch (_) {
      if (mounted)
        setState(
          () => _error = authText(
            'Unable to update password. Try again or request a new reset link.',
            'تعذر تغيير كلمة المرور. حاول مجددًا أو اطلب رابط استعادة جديدًا.',
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancelRecovery() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await AuthService().signOut();
      if (!mounted) return;
      AuthFlow.instance.finishRecovery();
      Get.offAll(() => const LoginView());
    } catch (_) {
      if (mounted)
        setState(
          () => _error = authText(
            'Unable to sign out. Please retry.',
            'تعذر تسجيل الخروج. حاول مجددًا.',
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.recovery && !_saving,
    child: Scaffold(
      body: AppTheme.backgroundGradient(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: AppTheme.glassPanel(
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!widget.recovery)
                          AppTheme.circleBackButton(
                            onTap: () {
                              if (!_saving) Get.back();
                            },
                          ),
                        Text(
                          authText('Change password', 'تغيير كلمة المرور'),
                          style: AppTheme.headingStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: AppTheme.inputDecoration(
                            hintText: authText(
                              'New password',
                              'كلمة المرور الجديدة',
                            ),
                          ),
                          validator: (v) => (v ?? '').length < 8
                              ? authText(
                                  'Use at least 8 characters.',
                                  'استخدم 8 أحرف على الأقل.',
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmation,
                          obscureText: true,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: AppTheme.inputDecoration(
                            hintText: authText(
                              'Confirm password',
                              'تأكيد كلمة المرور',
                            ),
                          ),
                          validator: (v) => v != _password.text
                              ? authText(
                                  'Passwords do not match.',
                                  'كلمتا المرور غير متطابقتين.',
                                )
                              : null,
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        const SizedBox(height: 24),
                        AppTheme.goldButton(
                          text: authText('Save password', 'حفظ كلمة المرور'),
                          onPressed: _save,
                          isLoading: _saving,
                        ),
                        if (widget.recovery)
                          TextButton(
                            onPressed: _saving ? null : _cancelRecovery,
                            child: Text(
                              authText(
                                'Cancel and sign out',
                                'إلغاء وتسجيل الخروج',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});
  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _phrase = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _phrase.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_busy || !ProfileValues.validDeletePhrase(_phrase.text)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService().deleteAccount(_phrase.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted)
        setState(
          () => _error = authText(
            'Account deletion failed. Please retry. Some scan images may already have been removed.',
            'تعذر حذف الحساب. حاول مجددًا. ربما حُذفت بعض صور الفحوصات بالفعل.',
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        authText('Delete account permanently?', 'حذف الحساب نهائيًا؟'),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            authText(
              'Your profile and scans will be permanently deleted. Type DELETE or delete my account to confirm.',
              'سيُحذف ملفك وفحوصاتك نهائيًا. اكتب حذف أو حذف حسابي للتأكيد.',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phrase,
            enabled: !_busy,
            onChanged: (_) => setState(() {}),
            decoration: AppTheme.inputDecoration(
              hintText: authText('DELETE', 'حذف'),
            ),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(authText('Cancel', 'إلغاء')),
        ),
        TextButton(
          onPressed: _busy || !ProfileValues.validDeletePhrase(_phrase.text)
              ? null
              : _delete,
          child: Text(
            _busy
                ? authText('Deleting…', 'جارٍ الحذف…')
                : authText('Delete account', 'حذف الحساب'),
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
}
