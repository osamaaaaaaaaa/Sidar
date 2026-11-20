import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ClimateData {
  final String city;
  final String country;
  final String countryCode;
  final String flag;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double uvIndex;
  final int aqi;
  final String aqiStatus;
  final Color aqiColor;
  final String uvStatus;
  final Color uvColor;
  final String humidityStatus;
  final Color humidityColor;
  final String conditionText;
  final IconData conditionIcon;
  final bool isDay;
  final String aiSkinAdvice;
  final DateTime updatedAt;
  final bool isLive;

  const ClimateData({
    required this.city,
    required this.country,
    required this.countryCode,
    required this.flag,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.uvIndex,
    required this.aqi,
    required this.aqiStatus,
    required this.aqiColor,
    required this.uvStatus,
    required this.uvColor,
    required this.humidityStatus,
    required this.humidityColor,
    required this.conditionText,
    required this.conditionIcon,
    required this.isDay,
    required this.aiSkinAdvice,
    required this.updatedAt,
    required this.isLive,
  });
}

class ClimateRadarService {
  ClimateRadarService._();
  static final ClimateRadarService instance = ClimateRadarService._();

  ClimateData? _cachedData;
  DateTime? _lastFetchTime;
  String? _lastLocationKey;

  /// Saudi Arabia's 5 major geographical regions with distinct climates
  static const List<Map<String, dynamic>> saudiRegions = [
    {
      'id': 'riyadh',
      'regionAr': 'الوسطى',
      'regionEn': 'Central',
      'cityAr': 'الرياض',
      'cityEn': 'Riyadh',
      'labelAr': 'الرياض (المنطقة الوسطى)',
      'labelEn': 'Riyadh (Central)',
      'lat': 24.7136,
      'lon': 46.6753,
    },
    {
      'id': 'jeddah',
      'regionAr': 'الغربية',
      'regionEn': 'Western',
      'cityAr': 'جدة',
      'cityEn': 'Jeddah',
      'labelAr': 'جدة (المنطقة الغربية)',
      'labelEn': 'Jeddah (Western)',
      'lat': 21.5433,
      'lon': 39.1728,
    },
    {
      'id': 'dammam',
      'regionAr': 'الشرقية',
      'regionEn': 'Eastern',
      'cityAr': 'الدمام',
      'cityEn': 'Dammam',
      'labelAr': 'الدمام (المنطقة الشرقية)',
      'labelEn': 'Dammam (Eastern)',
      'lat': 26.4207,
      'lon': 50.0888,
    },
    {
      'id': 'abha',
      'regionAr': 'الجنوبية',
      'regionEn': 'Southern',
      'cityAr': 'أبها',
      'cityEn': 'Abha',
      'labelAr': 'أبها (المنطقة الجنوبية)',
      'labelEn': 'Abha (Southern)',
      'lat': 18.2164,
      'lon': 42.5053,
    },
    {
      'id': 'tabuk',
      'regionAr': 'الشمالية',
      'regionEn': 'Northern',
      'cityAr': 'تبوك',
      'cityEn': 'Tabuk',
      'labelAr': 'تبوك (المنطقة الشمالية)',
      'labelEn': 'Tabuk (Northern)',
      'lat': 28.3835,
      'lon': 36.5662,
    },
  ];

  static Map<String, dynamic>? findSaudiRegion(String? query) {
    if (query == null || query.trim().isEmpty) return null;
    final q = query.trim().toLowerCase();
    for (final r in saudiRegions) {
      if (r['id'] == q ||
          r['cityAr'] == query.trim() ||
          r['cityEn'].toString().toLowerCase() == q ||
          r['labelAr'].toString().contains(query.trim()) ||
          q.contains(r['id']) ||
          q.contains(r['cityAr']) ||
          q.contains(r['cityEn'].toString().toLowerCase())) {
        return r;
      }
    }
    return null;
  }

  static const Map<String, Map<String, dynamic>> _countryCoords = {
    'EG': {
      'lat': 30.0444,
      'lon': 31.2357,
      'cityAr': 'القاهرة',
      'cityEn': 'Cairo',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'flag': '🇪🇬',
    },
    'SA': {
      'lat': 24.7136,
      'lon': 46.6753,
      'cityAr': 'الرياض',
      'cityEn': 'Riyadh',
      'countryAr': 'السعودية',
      'countryEn': 'Saudi Arabia',
      'flag': '🇸🇦',
    },
    'AE': {
      'lat': 25.2048,
      'lon': 55.2708,
      'cityAr': 'دبي',
      'cityEn': 'Dubai',
      'countryAr': 'الإمارات',
      'countryEn': 'UAE',
      'flag': '🇦🇪',
    },
    'KW': {
      'lat': 29.3759,
      'lon': 47.9774,
      'cityAr': 'الكويت',
      'cityEn': 'Kuwait City',
      'countryAr': 'الكويت',
      'countryEn': 'Kuwait',
      'flag': '🇰🇼',
    },
    'QA': {
      'lat': 25.2854,
      'lon': 51.5310,
      'cityAr': 'الدوحة',
      'cityEn': 'Doha',
      'countryAr': 'قطر',
      'countryEn': 'Qatar',
      'flag': '🇶🇦',
    },
    'BH': {
      'lat': 26.2285,
      'lon': 50.5860,
      'cityAr': 'المنامة',
      'cityEn': 'Manama',
      'countryAr': 'البحرين',
      'countryEn': 'Bahrain',
      'flag': '🇧🇭',
    },
    'OM': {
      'lat': 23.5880,
      'lon': 58.3829,
      'cityAr': 'مسقط',
      'cityEn': 'Muscat',
      'countryAr': 'عُمان',
      'countryEn': 'Oman',
      'flag': '🇴🇲',
    },
    'JO': {
      'lat': 31.9454,
      'lon': 35.9284,
      'cityAr': 'عمّان',
      'cityEn': 'Amman',
      'countryAr': 'الأردن',
      'countryEn': 'Jordan',
      'flag': '🇯🇴',
    },
    'LB': {
      'lat': 33.8938,
      'lon': 35.5018,
      'cityAr': 'بيروت',
      'cityEn': 'Beirut',
      'countryAr': 'لبنان',
      'countryEn': 'Lebanon',
      'flag': '🇱🇧',
    },
    'IQ': {
      'lat': 33.3152,
      'lon': 44.3661,
      'cityAr': 'بغداد',
      'cityEn': 'Baghdad',
      'countryAr': 'العراق',
      'countryEn': 'Iraq',
      'flag': '🇮🇶',
    },
    'MA': {
      'lat': 33.5731,
      'lon': -7.5898,
      'cityAr': 'الدار البيضاء',
      'cityEn': 'Casablanca',
      'countryAr': 'المغرب',
      'countryEn': 'Morocco',
      'flag': '🇲🇦',
    },
    'DZ': {
      'lat': 36.7538,
      'lon': 3.0588,
      'cityAr': 'الجزائر',
      'cityEn': 'Algiers',
      'countryAr': 'الجزائر',
      'countryEn': 'Algeria',
      'flag': '🇩🇿',
    },
    'TN': {
      'lat': 36.8065,
      'lon': 10.1815,
      'cityAr': 'تونس',
      'cityEn': 'Tunis',
      'countryAr': 'تونس',
      'countryEn': 'Tunisia',
      'flag': '🇹🇳',
    },
    'SD': {
      'lat': 15.5007,
      'lon': 32.5599,
      'cityAr': 'الخرطوم',
      'cityEn': 'Khartoum',
      'countryAr': 'السودان',
      'countryEn': 'Sudan',
      'flag': '🇸🇩',
    },
    'LY': {
      'lat': 32.8872,
      'lon': 13.1913,
      'cityAr': 'طرابلس',
      'cityEn': 'Tripoli',
      'countryAr': 'ليبيا',
      'countryEn': 'Libya',
      'flag': '🇱🇾',
    },
    'SY': {
      'lat': 33.5138,
      'lon': 36.2765,
      'cityAr': 'دمشق',
      'cityEn': 'Damascus',
      'countryAr': 'سوريا',
      'countryEn': 'Syria',
      'flag': '🇸🇾',
    },
    'YE': {
      'lat': 15.3694,
      'lon': 44.1910,
      'cityAr': 'صنعاء',
      'cityEn': 'Sanaa',
      'countryAr': 'اليمن',
      'countryEn': 'Yemen',
      'flag': '🇾🇪',
    },
    'PS': {
      'lat': 31.7683,
      'lon': 35.2137,
      'cityAr': 'القدس',
      'cityEn': 'Jerusalem',
      'countryAr': 'فلسطين',
      'countryEn': 'Palestine',
      'flag': '🇵🇸',
    },
    'TR': {
      'lat': 41.0082,
      'lon': 28.9784,
      'cityAr': 'إسطنبول',
      'cityEn': 'Istanbul',
      'countryAr': 'تركيا',
      'countryEn': 'Turkey',
      'flag': '🇹🇷',
    },
    'GB': {
      'lat': 51.5074,
      'lon': -0.1278,
      'cityAr': 'لندن',
      'cityEn': 'London',
      'countryAr': 'بريطانيا',
      'countryEn': 'United Kingdom',
      'flag': '🇬🇧',
    },
    'US': {
      'lat': 40.7128,
      'lon': -74.0060,
      'cityAr': 'نيويورك',
      'cityEn': 'New York',
      'countryAr': 'أمريكا',
      'countryEn': 'United States',
      'flag': '🇺🇸',
    },
    'FR': {
      'lat': 48.8566,
      'lon': 2.3522,
      'cityAr': 'باريس',
      'cityEn': 'Paris',
      'countryAr': 'فرنسا',
      'countryEn': 'France',
      'flag': '🇫🇷',
    },
    'DE': {
      'lat': 52.5200,
      'lon': 13.4050,
      'cityAr': 'برلين',
      'cityEn': 'Berlin',
      'countryAr': 'ألمانيا',
      'countryEn': 'Germany',
      'flag': '🇩🇪',
    },
  };

  Future<ClimateData> fetchClimateData({
    String? countryCode,
    String? cityName,
    bool isArabic = true,
    bool forceRefresh = false,
  }) async {
    final cleanCode = (countryCode ?? '').trim().toUpperCase();
    final effectiveCode = cleanCode.isNotEmpty ? cleanCode : 'EG';

    final loc = _countryCoords[effectiveCode] ?? _countryCoords['EG']!;
    double lat = loc['lat'] as double;
    double lon = loc['lon'] as double;
    String city = isArabic
        ? (loc['cityAr'] as String)
        : (loc['cityEn'] as String);
    String country = isArabic
        ? (loc['countryAr'] as String)
        : (loc['countryEn'] as String);
    String flag = loc['flag'] as String;

    // Check if a specific Saudi region/city was requested
    if (effectiveCode == 'SA' &&
        cityName != null &&
        cityName.trim().isNotEmpty) {
      final region = findSaudiRegion(cityName);
      if (region != null) {
        lat = region['lat'] as double;
        lon = region['lon'] as double;
        city = isArabic
            ? (region['cityAr'] as String)
            : (region['cityEn'] as String);
      }
    }

    final cacheKey =
        '$effectiveCode-${(cityName ?? city).trim().toLowerCase()}-${isArabic ? "ar" : "en"}';
    if (!forceRefresh &&
        _cachedData != null &&
        _lastLocationKey == cacheKey &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 15) {
      return _cachedData!;
    }

    try {
      if (effectiveCode != 'SA' &&
          cityName != null &&
          cityName.trim().isNotEmpty) {
        final geocodingUri =
            Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
              'name': cityName.trim(),
              'count': '100',
              'language': isArabic ? 'ar' : 'en',
              'countryCode': effectiveCode,
            });
        final response = await http
            .get(geocodingUri)
            .timeout(const Duration(seconds: 6));
        if (response.statusCode != 200) throw Exception('City lookup failed');
        final results =
            (jsonDecode(response.body) as Map<String, dynamic>)['results']
                as List<dynamic>? ??
            [];
        final matches = results.whereType<Map<String, dynamic>>().where(
          (result) => result['country_code'] == effectiveCode,
        );
        if (matches.isEmpty) {
          throw Exception('City not found in selected country');
        }
        final match = matches.first;
        lat = (match['latitude'] as num).toDouble();
        lon = (match['longitude'] as num).toDouble();
        city = match['name'] as String;
        country = match['country'] as String? ?? effectiveCode;
        if (effectiveCode.length == 2) {
          flag = String.fromCharCodes(
            effectiveCode.codeUnits.map((code) => 0x1F1E6 + code - 65),
          );
        }
      }
      // 1. Fetch Real Weather Forecast from Open-Meteo
      final weatherUri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code&daily=uv_index_max&timezone=auto',
      );
      final weatherResponse = await http
          .get(weatherUri)
          .timeout(const Duration(seconds: 4));

      double temp = 24.0;
      double feels = 24.0;
      int humidity = 50;
      int weatherCode = 0;
      bool isDay = true;
      double uvIndex = 4.0;

      if (weatherResponse.statusCode == 200) {
        final weatherJson =
            jsonDecode(weatherResponse.body) as Map<String, dynamic>;
        final current = weatherJson['current'] as Map<String, dynamic>?;
        if (current != null) {
          temp = (current['temperature_2m'] as num?)?.toDouble() ?? temp;
          feels =
              (current['apparent_temperature'] as num?)?.toDouble() ?? feels;
          humidity =
              (current['relative_humidity_2m'] as num?)?.toInt() ?? humidity;
          weatherCode =
              (current['weather_code'] as num?)?.toInt() ?? weatherCode;
          isDay = ((current['is_day'] as num?)?.toInt() ?? 1) == 1;
        }

        final daily = weatherJson['daily'] as Map<String, dynamic>?;
        final uvList = daily?['uv_index_max'] as List<dynamic>?;
        if (uvList != null && uvList.isNotEmpty) {
          uvIndex = (uvList.first as num?)?.toDouble() ?? uvIndex;
        }
      }

      // 2. Fetch Real Air Quality Index from Open-Meteo Air Quality
      int aqi = 45;
      try {
        final aqiUri = Uri.parse(
          'https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$lat&longitude=$lon&current=us_aqi,pm2_5',
        );
        final aqiResponse = await http
            .get(aqiUri)
            .timeout(const Duration(seconds: 4));
        if (aqiResponse.statusCode == 200) {
          final aqiJson = jsonDecode(aqiResponse.body) as Map<String, dynamic>;
          final currentAqi = aqiJson['current'] as Map<String, dynamic>?;
          if (currentAqi != null) {
            aqi = (currentAqi['us_aqi'] as num?)?.toInt() ?? aqi;
          }
        }
      } catch (e) {
        log('[ClimateRadarService] AQI fetch fallback: $e');
      }

      // 3. Interpret condition
      final conditionInfo = _interpretWeather(weatherCode, isDay, isArabic);

      // 4. Status levels and colors
      final uvInfo = _evaluateUv(uvIndex, isArabic);
      final aqiInfo = _evaluateAqi(aqi, isArabic);
      final humidityInfo = _evaluateHumidity(humidity, isArabic);

      // 5. Intelligent AI Clinical Skincare Guidance
      final advice = _generateAiSkinAdvice(
        temp: temp,
        humidity: humidity,
        uv: uvIndex,
        isDay: isDay,
        isArabic: isArabic,
      );

      final result = ClimateData(
        city: city,
        country: country,
        countryCode: effectiveCode,
        flag: flag,
        temperature: temp,
        feelsLike: feels,
        humidity: humidity,
        uvIndex: uvIndex,
        aqi: aqi,
        aqiStatus: aqiInfo['status'] as String,
        aqiColor: aqiInfo['color'] as Color,
        uvStatus: uvInfo['status'] as String,
        uvColor: uvInfo['color'] as Color,
        humidityStatus: humidityInfo['status'] as String,
        humidityColor: humidityInfo['color'] as Color,
        conditionText: conditionInfo['text'] as String,
        conditionIcon: conditionInfo['icon'] as IconData,
        isDay: isDay,
        aiSkinAdvice: advice,
        updatedAt: DateTime.now(),
        isLive: true,
      );

      _cachedData = result;
      _lastFetchTime = DateTime.now();
      _lastLocationKey = cacheKey;
      return result;
    } catch (e, s) {
      log(
        '[ClimateRadarService] Live fetch error: $e',
        error: e,
        stackTrace: s,
      );
      // If we had cached data, return it
      if (_cachedData != null && _lastLocationKey == cacheKey) {
        return _cachedData!;
      }
      // Return safe realistic fallback
      return _generateFallback(effectiveCode, isArabic, cityName);
    }
  }

  Map<String, dynamic> _interpretWeather(int code, bool isDay, bool isArabic) {
    if (code == 0) {
      return {
        'text': isArabic
            ? (isDay ? 'مشمس صافٍ' : 'سماء صافية')
            : (isDay ? 'Clear Sky' : 'Clear Night'),
        'icon': isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round,
      };
    } else if (code <= 3) {
      return {
        'text': isArabic ? 'غائم جزئياً' : 'Partly Cloudy',
        'icon': Icons.wb_cloudy_rounded,
      };
    } else if (code == 45 || code == 48) {
      return {
        'text': isArabic ? 'ضبابي' : 'Foggy',
        'icon': Icons.cloud_queue_rounded,
      };
    } else if (code >= 51 && code <= 67) {
      return {
        'text': isArabic ? 'أمطار خفيفة' : 'Rainy',
        'icon': Icons.grain_rounded,
      };
    } else if (code >= 80 && code <= 82) {
      return {
        'text': isArabic ? 'زخات مطر' : 'Rain Showers',
        'icon': Icons.water_drop_rounded,
      };
    } else if (code >= 95) {
      return {
        'text': isArabic ? 'عاصف رعدي' : 'Thunderstorm',
        'icon': Icons.flash_on_rounded,
      };
    } else {
      return {
        'text': isArabic ? 'معتدل' : 'Pleasant',
        'icon': Icons.wb_sunny_outlined,
      };
    }
  }

  Map<String, dynamic> _evaluateUv(double uv, bool isArabic) {
    if (uv >= 8.0) {
      return {
        'status': isArabic ? 'مرتفع جداً' : 'Very High',
        'color': const Color(0xFFC0392B),
      };
    } else if (uv >= 6.0) {
      return {
        'status': isArabic ? 'مرتفع' : 'High',
        'color': const Color(0xFFE67E22),
      };
    } else if (uv >= 3.0) {
      return {
        'status': isArabic ? 'معتدل' : 'Moderate',
        'color': const Color(0xFFC8A66A),
      };
    } else {
      return {
        'status': isArabic ? 'منخفض' : 'Low',
        'color': const Color(0xFF178568),
      };
    }
  }

  Map<String, dynamic> _evaluateAqi(int aqi, bool isArabic) {
    if (aqi > 150) {
      return {
        'status': isArabic ? 'غير صحي' : 'Unhealthy',
        'color': const Color(0xFFC0392B),
      };
    } else if (aqi > 100) {
      return {
        'status': isArabic ? 'حساس' : 'Sensitive',
        'color': const Color(0xFFE67E22),
      };
    } else if (aqi > 50) {
      return {
        'status': isArabic ? 'معتدل' : 'Moderate',
        'color': const Color(0xFFC8A66A),
      };
    } else {
      return {
        'status': isArabic ? 'نقي وممتاز' : 'Clean & Fresh',
        'color': const Color(0xFF178568),
      };
    }
  }

  Map<String, dynamic> _evaluateHumidity(int hum, bool isArabic) {
    if (hum > 70) {
      return {
        'status': isArabic ? 'رطب جداً' : 'Very Humid',
        'color': const Color(0xFF0F5F4D),
      };
    } else if (hum < 30) {
      return {
        'status': isArabic ? 'جاف' : 'Dry',
        'color': const Color(0xFFE67E22),
      };
    } else {
      return {
        'status': isArabic ? 'مثالي' : 'Balanced',
        'color': const Color(0xFF178568),
      };
    }
  }

  String _generateAiSkinAdvice({
    required double temp,
    required int humidity,
    required double uv,
    required bool isDay,
    required bool isArabic,
  }) {
    if (isArabic) {
      if (!isDay) {
        return 'أجواء مسائية هادئة: وقت مثالي للسيروم العلاجي والريتينول لتجديد الخلايا أثناء النوم.';
      }
      if (uv >= 6.0) {
        return 'إشعاع UV مرتفع (${uv.toStringAsFixed(1)}): واقي شمس SPF 50+ إلزامي وتجديده كل ساعتين.';
      }
      if (humidity < 35) {
        return 'هواء جاف ($humidity% رطوبة): عزز حاجز بشرتك بهيالورونيك أسيد ومرطب مكثف.';
      }
      if (humidity > 65) {
        return 'رطوبة مرتفعة ($humidity%): يُنصح بغسول رغوي منقٍ ومرطب خفيف مائي القاعدة.';
      }
      if (temp >= 32) {
        return 'طقس حار (${temp.round()}°C): حافظ على ترطيب الجسم ورذاذ مهدئ للبشرة (Thermal Mist).';
      }
      if (temp <= 16) {
        return 'أجواء باردة (${temp.round()}°C): ادعم حاجز الدهون بكريم غني بالسيراميد لمنع التشققات.';
      }
      return 'طقس اليوم معتدل ومثالي: واقي شمس خفيف مع روتينك المعتاد للحفاظ على إشراقة البشرة.';
    } else {
      if (!isDay) {
        return 'Night Routine: Ideal time for cellular renewal with retinol and treatment serum.';
      }
      if (uv >= 6.0) {
        return 'High UV Index (${uv.toStringAsFixed(1)}): Broad spectrum SPF 50+ is essential; reapply every 2 hours.';
      }
      if (humidity < 35) {
        return 'Dry air ($humidity%): Boost skin hydration with hyaluronic acid and a rich barrier cream.';
      }
      if (humidity > 65) {
        return 'High humidity ($humidity%): Lightweight oil-free moisturizer & clarifying cleanser recommended.';
      }
      if (temp >= 32) {
        return 'Hot weather (${temp.round()}°C): Stay hydrated and soothe skin with refreshing thermal mist.';
      }
      if (temp <= 16) {
        return 'Cool weather (${temp.round()}°C): Strengthen lipid barrier with ceramide-infused moisturizer.';
      }
      return 'Optimal balanced climate: Lightweight SPF and daily hydration maintain your skin radiance.';
    }
  }

  ClimateData _generateFallback(
    String code,
    bool isArabic, [
    String? cityName,
  ]) {
    final loc = _countryCoords[code] ?? _countryCoords['EG']!;
    String city = cityName?.trim().isNotEmpty == true
        ? cityName!.trim()
        : (isArabic ? (loc['cityAr'] as String) : (loc['cityEn'] as String));
    if (code == 'SA' && cityName != null && cityName.trim().isNotEmpty) {
      final region = findSaudiRegion(cityName);
      if (region != null) {
        city = isArabic
            ? (region['cityAr'] as String)
            : (region['cityEn'] as String);
      }
    }
    return ClimateData(
      city: city,
      country: !_countryCoords.containsKey(code)
          ? code
          : (isArabic
                ? (loc['countryAr'] as String)
                : (loc['countryEn'] as String)),
      countryCode: code,
      flag: code.length == 2 && RegExp(r'^[A-Z]{2}$').hasMatch(code)
          ? String.fromCharCodes(code.codeUnits.map((c) => 0x1F1E6 + c - 65))
          : loc['flag'] as String,
      temperature: 24.0,
      feelsLike: 23.5,
      humidity: 50,
      uvIndex: 4.2,
      aqi: 45,
      aqiStatus: isArabic ? 'نقي وممتاز' : 'Clean & Fresh',
      aqiColor: const Color(0xFF178568),
      uvStatus: isArabic ? 'معتدل' : 'Moderate',
      uvColor: const Color(0xFFC8A66A),
      humidityStatus: isArabic ? 'متوازن' : 'Balanced',
      humidityColor: const Color(0xFF178568),
      conditionText: isArabic ? 'مشمس معتدل' : 'Sunny & Pleasant',
      conditionIcon: Icons.wb_sunny_rounded,
      isDay: true,
      aiSkinAdvice: isArabic
          ? 'طقس اليوم معتدل، يُنصح بمرطب مائي خفيف وواقي شمس'
          : 'Pleasant weather: light water-based moisturizer & SPF recommended',
      updatedAt: DateTime.now(),
      isLive: false,
    );
  }
}
