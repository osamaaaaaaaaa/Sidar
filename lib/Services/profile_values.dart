/// Values shared with the active portal; labels must never be persisted.
class ProfileValues {
  static const genders = ['male', 'female', 'other'];
  static const skinTypes = [
    'normal',
    'dry',
    'oily',
    'combination',
    'sensitive',
    'unknown',
  ];

  // Union of COUNTRY_CODES and POPULAR_COUNTRY_CODES in portal/app.js.
  static final countries = <String>{
    ...'SA AE EG KW QA BH OM JO IQ MA DZ TN LB SD LY YE SY PS GB US TR DE FR'
        .split(' '),
    ...'AF AL DZ AD AO AG AR AM AU AT AZ BS BH BD BB BY BE BZ BJ BT BO BA BW BR BN BG BF BI CV KH CM CA CF TD CL CN CO KM CG CD CR CI HR CU CY CZ DK DJ DM DO EC EG SV GQ ER EE SZ ET FJ FI FR GA GM GE DE GH GR GD GT GN GW GY HT HN HU IS IN ID IR IQ IE IL IT JM JP JO KZ KE KI KW KG LA LV LB LS LR LY LI LT LU MG MW MY MV ML MT MH MR MU MX FM MD MC MN ME MA MZ MM NA NR NP NL NZ NI NE NG KP MK NO OM PK PW PA PG PY PE PH PL PT QA RO RU RW KN LC VC WS SM ST SA SN RS SC SL SG SK SI SB SO ZA KR SS ES LK SD SR SE CH SY TJ TZ TH TL TG TO TT TN TR TM TV UG UA AE GB US UY UZ VU VA VE VN YE ZM ZW'
        .split(' '),
  }.toList(growable: false);

  static String? gender(Object? value) {
    final text = value?.toString().trim().toLowerCase();
    return const {
      'male': 'male',
      'ذكر': 'male',
      'female': 'female',
      'أنثى': 'female',
      'انثى': 'female',
      'other': 'other',
      'آخر': 'other',
      'أخرى': 'other',
      'اخر': 'other',
    }[text];
  }

  static String? skinType(Object? value) {
    final text = value
        ?.toString()
        .trim()
        .toLowerCase()
        .replaceFirst(RegExp(r'^(البشرة|بشرة)\s+'), '')
        .replaceFirst(RegExp(r'\s+skin$'), '')
        .replaceFirst(RegExp(r'_skin$'), '');
    return const {
      'normal': 'normal',
      'عادية': 'normal',
      'عادي': 'normal',
      'العادية': 'normal',
      'dry': 'dry',
      'جافة': 'dry',
      'جاف': 'dry',
      'الجافة': 'dry',
      'oily': 'oily',
      'دهنية': 'oily',
      'دهني': 'oily',
      'الدهنية': 'oily',
      'combination': 'combination',
      'مختلطة': 'combination',
      'مختلط': 'combination',
      'المختلطة': 'combination',
      'sensitive': 'sensitive',
      'حساسة': 'sensitive',
      'حساس': 'sensitive',
      'الحساسة': 'sensitive',
      'unknown': 'unknown',
      'not_sure': 'unknown',
      'لا أعرف': 'unknown',
      'لا اعرف': 'unknown',
      'غير متأكد': 'unknown',
      'غير متأكدة': 'unknown',
    }[text];
  }

  static String? country(Object? value) {
    final code = value?.toString().trim().toUpperCase();
    return countries.contains(code) ? code : null;
  }

  static bool isMissing(Object? value) =>
      value == null || (value is String && value.trim().isEmpty);

  static bool validAge(String value) {
    if (value.trim().isEmpty) return true;
    final age = int.tryParse(value.trim());
    return age != null && age >= 1 && age <= 120;
  }

  static String? validateProfile({
    required String name,
    required String age,
    String? genderValue,
    String? skin,
    String? location,
  }) {
    if (name.trim().isEmpty) return 'name';
    if (!validAge(age)) return 'age';
    if (!isMissing(genderValue) && gender(genderValue) == null) return 'gender';
    if (skinType(skin) == null) return 'skin';
    if (country(location) == null) return 'country';
    return null;
  }

  static bool validDeletePhrase(String phrase) {
    final value = phrase.trim().toLowerCase();
    return const [
      'delete',
      'حذف',
      'delete my account',
      'حذف حسابي',
    ].contains(value);
  }

  static String? validatePassword(String password, String confirmation) {
    if (password.length < 8) return 'length';
    if (password != confirmation) return 'match';
    return null;
  }

  /// Normalize known legacy labels without changing the user's choices.
  /// Unknown values remain untouched; never silently turn them into 'normal'.
  static Map<String, dynamic> canonicalStoredFields(Map<String, dynamic> row) {
    final patch = <String, dynamic>{};
    final savedGender = gender(row['gender']);
    final savedSkin = skinType(row['skin_type']);
    if (savedGender != null && savedGender != row['gender']) {
      patch['gender'] = savedGender;
    }
    if (savedSkin != null && savedSkin != row['skin_type']) {
      patch['skin_type'] = savedSkin;
    }
    return patch;
  }

  /// Only backfill absent fields. False, zero and saved profile choices win
  /// over provider/signup metadata, including on repeated Google sign-ins.
  static Map<String, dynamic> missingProfileFields(
    Map<String, dynamic> existing,
    Map<String, dynamic> metadata,
  ) {
    final patch = <String, dynamic>{};
    for (final key in const [
      'full_name',
      'avatar_url',
      'age',
      'gender',
      'skin_type',
      'location_text',
      'preferred_language',
      'allergies',
      'medications',
      'sun_sensitive',
    ]) {
      if (!isMissing(existing[key]) || isMissing(metadata[key])) continue;
      dynamic value = metadata[key];
      if (key == 'gender') value = gender(value);
      if (key == 'skin_type') value = skinType(value);
      if (key == 'location_text') value = country(value);
      if (key == 'age') {
        value = int.tryParse(value.toString());
        if (value == null || value < 1 || value > 120) continue;
      }
      if (key == 'preferred_language' && !['ar', 'en'].contains(value))
        continue;
      if (value != null) patch[key] = value;
    }
    return patch;
  }
}

/// Always drain page zero: advancing an offset after deletion skips objects.
/// Callbacks make this independently testable without touching live storage.
Future<void> drainOwnedImages({
  required String owner,
  required Future<List<({String name, bool folder})>> Function(String path)
  listFirstPage,
  required Future<void> Function(List<String> paths) remove,
  required void Function() checkSession,
}) async {
  if (owner.isEmpty || owner.contains('/') || owner == '.' || owner == '..') {
    throw ArgumentError('Invalid owner');
  }
  Future<void> drain(String path) async {
    String? previousPage;
    while (true) {
      checkSession();
      final entries = await listFirstPage(path);
      if (entries.isEmpty) return;
      final signature = entries.map((e) => '${e.name}:${e.folder}').join('|');
      if (signature == previousPage)
        throw StateError('Storage cleanup made no progress');
      previousPage = signature;
      final files = <String>[];
      for (final entry in entries) {
        if (entry.name.isEmpty ||
            entry.name.contains('/') ||
            entry.name == '.' ||
            entry.name == '..') {
          throw StateError('Invalid storage object');
        }
        final child = '$path/${entry.name}';
        if (entry.folder) {
          await drain(child);
        } else {
          files.add(child);
        }
      }
      if (files.isNotEmpty) {
        checkSession();
        await remove(files);
      }
    }
  }

  await drain(owner);
}
