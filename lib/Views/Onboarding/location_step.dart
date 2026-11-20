import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skincare/Services/auth_profile_ui.dart';
import 'package:skincare/Services/climate_radar_service.dart';
import 'package:skincare/Services/profile_values.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';

Map<String, List<List<String>>> _decodeCities(String source) {
  final data = jsonDecode(source) as Map<String, dynamic>;
  return data.map(
    (code, entries) => MapEntry(
      code,
      (entries as List).map((entry) => (entry as List).cast<String>()).toList(),
    ),
  );
}

class LocationStep extends StatefulWidget {
  const LocationStep({
    super.key,
    required this.isArabic,
    required this.country,
    required this.city,
    required this.onLocationChanged,
    required this.onContinue,
  });
  final bool isArabic;
  final String? country;
  final String? city;
  final void Function(String? country, String? city) onLocationChanged;
  final VoidCallback onContinue;

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  Map<String, List<List<String>>>? _cities;
  bool _failed = false;
  List<LocationOption> _countries = [];
  List<LocationOption> _countryCities = [];

  @override
  void initState() {
    super.initState();
    _makeCountries();
    _makeCities();
    _loadCities();
  }

  @override
  void didUpdateWidget(covariant LocationStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isArabic != oldWidget.isArabic) _makeCountries();
    if (widget.isArabic != oldWidget.isArabic ||
        widget.country != oldWidget.country) {
      _makeCities();
    }
  }

  void _makeCountries() {
    _countries = ProfileValues.countries.map((code) {
      final names = countryNames[code];
      return LocationOption(
        code,
        names == null ? code : (widget.isArabic ? names.$2 : names.$1),
        '${names?.$1 ?? ''} ${names?.$2 ?? ''} $code',
      );
    }).toList()..sort((a, b) => a.label.compareTo(b.label));
  }

  void _makeCities() {
    _countryCities = widget.country == 'SA'
        ? ClimateRadarService.saudiRegions
              .map(
                (region) => LocationOption(
                  region['id'] as String,
                  region[widget.isArabic ? 'labelAr' : 'labelEn'] as String,
                  '${region['id']} ${region['labelAr']} ${region['labelEn']}',
                ),
              )
              .toList()
        : (_cities?[widget.country] ?? [])
              .map(
                (city) => LocationOption(
                  city[0],
                  widget.isArabic ? city[1] : city[2],
                  '${city[0]} ${city[1]} ${city[2]}',
                ),
              )
              .toList();
    _countryCities.sort((a, b) => a.label.compareTo(b.label));
  }

  Future<void> _loadCities() async {
    setState(() => _failed = false);
    try {
      final data = await rootBundle.loadString('assets/data/cities.json');
      final cities = await compute(_decodeCities, data);
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _makeCities();
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.isArabic;
    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ar ? 'أين تقيم؟' : 'Where do you live?',
            style: AppTheme.headingStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            ar
                ? 'اختر الدولة والمدينة لتناسب التوصيات مناخ منطقتك.'
                : 'Choose your country and city for local recommendations.',
            style: AppTheme.bodyStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          Text(
            ar ? 'الدولة' : 'Country',
            style: AppTheme.headingStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          LocationDropdown(
            key: ValueKey('country_$ar'),
            value: widget.country,
            options: _countries,
            hint: ar ? 'ابحث عن الدولة' : 'Search countries',
            icon: Icons.public_rounded,
            noResults: ar ? 'لا توجد نتائج' : 'No results',
            onSelected: (value) => widget.onLocationChanged(
              value,
              value == widget.country ? widget.city : null,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            ar ? 'المدينة / المنطقة' : 'City / Region',
            style: AppTheme.headingStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          LocationDropdown(
            key: ValueKey('city_${widget.country}_$ar'),
            value: widget.city,
            options: _countryCities,
            enabled: widget.country != null && _countryCities.isNotEmpty,
            hint: widget.country == null
                ? (ar ? 'اختر الدولة أولاً' : 'Choose a country first')
                : _cities == null && widget.country != 'SA'
                ? (ar ? 'جارٍ تحميل المدن' : 'Loading cities')
                : _countryCities.isEmpty
                ? (ar ? 'لا توجد مدن متاحة' : 'No cities available')
                : (ar ? 'ابحث عن المدينة' : 'Search cities'),
            icon: Icons.location_on_outlined,
            noResults: ar ? 'لا توجد نتائج' : 'No results',
            onSelected: (value) =>
                widget.onLocationChanged(widget.country, value),
          ),
          if (_failed)
            TextButton(
              onPressed: _loadCities,
              child: Text(ar ? 'إعادة تحميل المدن' : 'Retry loading cities'),
            ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: widget.city == null ? null : widget.onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.oliveGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(ar ? 'متابعة' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

String _normalize(String value) => value
    .toLowerCase()
    .trim()
    .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

class LocationOption {
  LocationOption(this.value, this.label, String terms)
    : search = _normalize(terms);
  final String value;
  final String label;
  final String search;
}

class LocationDropdown extends StatefulWidget {
  const LocationDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.hint,
    required this.icon,
    required this.noResults,
    required this.onSelected,
    this.enabled = true,
  });
  final String? value;
  final List<LocationOption> options;
  final String hint;
  final IconData icon;
  final String noResults;
  final ValueChanged<String?> onSelected;
  final bool enabled;

  @override
  State<LocationDropdown> createState() => LocationDropdownState();
}

class LocationDropdownState extends State<LocationDropdown> {
  final _text = TextEditingController();
  final _menu = MenuController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _syncValue();
  }

  @override
  void didUpdateWidget(covariant LocationDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null &&
        (widget.value != oldWidget.value ||
            widget.options != oldWidget.options)) {
      _syncValue();
    }
  }

  void _syncValue() {
    for (final option in widget.options) {
      if (option.value == widget.value) {
        _text.text = option.label;
        break;
      }
    }
    if (widget.value == null) _text.clear();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _normalize(_query);
    final matches = query.isEmpty
        ? widget.options
        : widget.options.where((o) => o.search.contains(query)).toList();
    return LayoutBuilder(
      builder: (context, constraints) => MenuAnchor(
        controller: _menu,
        crossAxisUnconstrained: false,
        onClose: _syncValue,
        menuChildren: [
          SizedBox(
            width: constraints.maxWidth,
            height: matches.isEmpty
                ? 56
                : (matches.length * 48.0).clamp(48.0, 240.0),
            child: matches.isEmpty
                ? Center(child: Text(widget.noResults))
                : ListView.builder(
                    primary: false,
                    padding: EdgeInsets.zero,
                    itemExtent: 48,
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final option = matches[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          option.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          _text.text = option.label;
                          _menu.close();
                          widget.onSelected(option.value);
                          FocusScope.of(context).unfocus();
                        },
                      );
                    },
                  ),
          ),
        ],
        builder: (context, menu, child) => TextField(
          controller: _text,
          enabled: widget.enabled,
          onTap: () {
            if (!menu.isOpen) {
              setState(() => _query = widget.value == null ? _text.text : '');
              menu.open();
            }
          },
          onChanged: (value) {
            setState(() => _query = value);
            if (!menu.isOpen) menu.open();
          },
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(widget.icon, color: AppColors.primary),
            suffixIcon: const Icon(Icons.arrow_drop_down),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
