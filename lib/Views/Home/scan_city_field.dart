import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skincare/Services/scan_controller.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';
import 'package:skincare/Views/Shared/country_city_dropdown.dart';

class ScanCityField extends StatelessWidget {
  const ScanCityField({
    super.key,
    required this.controller,
    required this.isArabic,
    this.cityData,
  });
  final ScanController controller;
  final bool isArabic;
  @visibleForTesting
  final Future<Map<String, dynamic>>? cityData;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        isArabic ? 'المدينة' : 'City',
        style: AppTheme.bodyStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 8),
      Obx(
        () => CountryCityDropdown(
          country: controller.locationText.value,
          city: controller.selectedCity.value,
          isArabic: isArabic,
          loading: controller.isProfileLoading.value,
          onChanged: controller.setScanCity,
          cityData: cityData,
        ),
      ),
    ],
  );
}
