import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skincare/Services/climate_radar_service.dart';
import 'package:skincare/Views/Onboarding/location_step.dart';

Future<Map<String, dynamic>>? _cityLabels;

Future<Map<String, dynamic>> _loadCityLabels() => _cityLabels ??= () async {
  final json = await rootBundle.loadString('assets/data/cities.json');
  return (await compute(jsonDecode, json)) as Map<String, dynamic>;
}();

class CountryCityDropdown extends StatelessWidget {
  const CountryCityDropdown({
    super.key,
    required this.country,
    required this.city,
    required this.isArabic,
    required this.onChanged,
    this.loading = false,
    this.cityData,
  });
  final String? country;
  final String? city;
  final bool isArabic;
  final bool loading;
  final ValueChanged<String?> onChanged;
  @visibleForTesting
  final Future<Map<String, dynamic>>? cityData;

  @override
  Widget build(BuildContext context) {
    final ar = isArabic;
    final code = (country ?? '').trim().toUpperCase();
    if (code == 'SA') {
      final regions = ClimateRadarService.saudiRegions
          .map(
            (region) => LocationOption(
              region['id'] as String,
              region[ar ? 'labelAr' : 'labelEn'] as String,
              '${region['id']} ${region['labelAr']} ${region['labelEn']}',
            ),
          )
          .toList();
      final selected =
          ClimateRadarService.findSaudiRegion(city)?['id'] as String? ?? city;
      return _dropdown(code, selected, regions, loading);
    }
    if (code.isEmpty) return _dropdown(code, city, [], loading);
    return FutureBuilder<Map<String, dynamic>>(
      future: cityData ?? _loadCityLabels(),
      builder: (context, snapshot) {
        final entries = snapshot.data?[code] as List? ?? [];
        final options =
            entries
                .map(
                  (entry) => LocationOption(
                    entry[0] as String,
                    entry[ar ? 1 : 2] as String,
                    '${entry[0]} ${entry[1]} ${entry[2]}',
                  ),
                )
                .toList()
              ..sort((a, b) => a.label.compareTo(b.label));
        return _dropdown(
          code,
          city,
          options,
          loading || snapshot.connectionState != ConnectionState.done,
          failed: snapshot.hasError,
        );
      },
    );
  }

  Widget _dropdown(
    String country,
    String? value,
    List<LocationOption> options,
    bool loading, {
    bool failed = false,
  }) {
    final ar = isArabic;
    if (value != null &&
        value.isNotEmpty &&
        !options.any((option) => option.value == value)) {
      options = [LocationOption(value, value, value), ...options];
    }
    final hint = loading
        ? (ar ? 'جارٍ تحميل المدينة...' : 'Loading cities...')
        : country.isEmpty
        ? (ar ? 'اختر الدولة أولاً' : 'Choose a country first')
        : failed
        ? (ar ? 'تعذر تحميل المدن' : 'Unable to load cities')
        : options.isEmpty
        ? (ar ? 'لا توجد مدن متاحة' : 'No cities available')
        : (ar ? 'ابحث عن المدينة' : 'Search cities');
    return LocationDropdown(
      key: ValueKey('city_${country}_$ar'),
      value: value,
      options: options,
      enabled: !loading && !failed && country.isNotEmpty && options.isNotEmpty,
      hint: hint,
      icon: Icons.location_city_rounded,
      noResults: ar ? 'لا توجد نتائج' : 'No results',
      onSelected: onChanged,
    );
  }
}
