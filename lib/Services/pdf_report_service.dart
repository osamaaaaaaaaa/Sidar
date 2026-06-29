import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:skincare/Models/ScanAiModel.dart';

/// Shared formatting keeps the screen, history and exported report consistent.
class ReportPresentation {
  static String text(String value) =>
      value.trim().isEmpty ? '--' : value.trim();

  static String score(double? value) {
    if (value == null || !value.isFinite) return '--';
    return '${value == value.roundToDouble() ? value.toInt() : value}%';
  }

  static String priority(String urgency, bool isArabic) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return isArabic ? 'أولوية عاجلة' : 'High priority';
      case 'medium':
        return isArabic ? 'أولوية متوسطة' : 'Medium priority';
      case 'low':
        return isArabic ? 'أولوية اعتيادية' : 'Low priority';
      default:
        return '--';
    }
  }

  static String target(ScanAiResult result, bool isArabic) {
    switch (result.analysisTarget.toLowerCase()) {
      case 'hair':
        return isArabic ? 'الشعر' : 'Hair';
      case 'skin':
        return isArabic ? 'البشرة' : 'Skin';
      case 'both':
        return isArabic ? 'البشرة والشعر' : 'Skin & Hair';
      default:
        return text(result.analysisTarget);
    }
  }

  static String imageQuality(String value, bool isArabic) {
    switch (value.trim().toLowerCase()) {
      case 'good':
        return isArabic ? 'جيدة' : 'Good';
      case 'medium':
      case 'moderate':
        return isArabic ? 'متوسطة' : 'Medium';
      case 'low':
      case 'poor':
        return isArabic ? 'منخفضة' : 'Low';
      default:
        return text(value);
    }
  }

  static Map<String, double?> metrics(ScanAiResult result, bool isArabic) {
    final hair = <String, double?>{
      isArabic ? 'كثافة الشعر' : 'Hair density': result.hairDensityScore,
      isArabic ? 'ملمس الشعر' : 'Hair texture': result.hairTextureScore,
      isArabic ? 'قوة الشعر' : 'Hair strength': result.hairStrengthScore,
      isArabic ? 'صحة فروة الرأس' : 'Scalp health': result.scalpHealthScore,
    };
    final skin = <String, double?>{
      isArabic ? 'الترطيب' : 'Hydration': result.hydrationScore,
      isArabic ? 'صفاء المسام' : 'Pore clarity': result.poreClarityScore,
      isArabic ? 'الخطوط الدقيقة' : 'Fine lines': result.fineLinesScore,
      isArabic ? 'تجانس اللون' : 'Overall tone': result.overallToneScore,
    };
    if (result.analysisTarget.toLowerCase() == 'hair') {
      return hair;
    }
    if (result.analysisTarget.toLowerCase() == 'both') {
      return {...skin, ...hair};
    }
    return skin;
  }

  static String date(DateTime? value) {
    if (value == null) return '--';
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  /// Catalog links may open a website, never executable/custom URL schemes.
  static Uri? safeExternalUri(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !['https', 'http'].contains(uri.scheme.toLowerCase()) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri;
  }
}

class PdfReportService {
  static Future<Uint8List> generateReportBytes({
    required ScanAiResult result,
    required bool isArabic,
    String? patientName,
    DateTime? reportTimestamp,
  }) async {
    final pdf = pw.Document();
    // Bundled TrueType fonts cover both Arabic and Latin without network access.
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/ar/IBMPlexSansArabic-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/ar/IBMPlexSansArabic-Bold.ttf'),
    );
    pw.MemoryImage? emblemImage;
    try {
      final bytes = await rootBundle.load(
        'assets/images/sidar-emblem-clean.png',
      );
      emblemImage = pw.MemoryImage(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    } catch (_) {
      // A missing decorative asset must not prevent sharing a report.
    }

    final lang = isArabic ? 'ar' : 'en';
    String label(String ar, String en) => isArabic ? ar : en;
    final emerald = PdfColor.fromHex('0F5F4D');
    final gold = PdfColor.fromHex('C8A66A');
    final cream = PdfColor.fromHex('FAF8F1');
    final mutedText = PdfColor.fromHex('53756C');
    final borderColor = PdfColor.fromHex('D9BF8A');
    final textStyle = pw.TextStyle(
      font: regularFont,
      fontSize: 11,
      color: emerald,
    );

    pw.Widget heading(String title) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(font: boldFont, fontSize: 14, color: emerald),
      ),
    );
    pw.Widget paragraph(String value) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Text(ReportPresentation.text(value), style: textStyle),
    );
    List<pw.Widget> steps(
      String title,
      List<String> items, {
      bool showEmpty = false,
    }) {
      if (items.isEmpty && !showEmpty) return [];
      return [
        heading(title),
        if (items.isEmpty) paragraph('--'),
        ...items.asMap().entries.map(
          (entry) => paragraph('${entry.key + 1}. ${entry.value}'),
        ),
      ];
    }

    pw.Widget metadata(String title, String value) =>
        paragraph('$title: $value');
    List<pw.Widget> catalog(
      String title,
      List<Map<String, dynamic>> items, {
      required bool doctors,
    }) {
      return [
        heading(title),
        if (items.isEmpty)
          paragraph(
            label(
              'لا توجد توصيات من الدليل متاحة.',
              'No catalog recommendations available.',
            ),
          ),
        for (final item in items) ...[
          paragraph(ReportPresentation.text(item['name']?.toString() ?? '')),
          if (doctors) ...[
            if ((item['specialty'] ?? '').toString().trim().isNotEmpty)
              paragraph(item['specialty'].toString()),
            if ((item['address'] ?? '').toString().trim().isNotEmpty)
              paragraph(item['address'].toString()),
          ] else ...[
            if ((item['desc'] ?? '').toString().trim().isNotEmpty)
              paragraph(item['desc'].toString()),
            metadata(
              label('السعر', 'Price'),
              ReportPresentation.text(item['price']?.toString() ?? ''),
            ),
          ],
          if (ReportPresentation.safeExternalUri(item['link'])
              case final Uri uri)
            pw.UrlLink(
              destination: uri.toString(),
              child: pw.Text(
                uri.toString(),
                textDirection: pw.TextDirection.ltr,
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 10,
                  color: emerald,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
          pw.SizedBox(height: 8),
        ],
      ];
    }

    pw.Widget reportHeader({bool compact = false}) => pw.Container(
      padding: pw.EdgeInsets.only(bottom: compact ? 9 : 16),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: gold, width: 1.5)),
      ),
      child: pw.Row(
        children: [
          if (emblemImage != null) ...[
            pw.SizedBox(
              width: compact ? 30 : 48,
              height: compact ? 30 : 48,
              child: pw.Image(emblemImage),
            ),
            pw.SizedBox(width: compact ? 8 : 12),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SIDAR AI',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: compact ? 14 : 22,
                    color: emerald,
                  ),
                ),
                if (!compact)
                  pw.Text(
                    label('تقرير العناية الشخصية', 'Personal care report'),
                    style: textStyle,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    pw.Widget metricTile(String title, double? value) => pw.Container(
      width: 125,
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: borderColor, width: .5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 8.5,
              color: mutedText,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            ReportPresentation.score(value),
            style: pw.TextStyle(font: boldFont, fontSize: 14, color: emerald),
          ),
        ],
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        build: (context) => pw.Column(
          children: [
            reportHeader(),
            heading(
              result.title.trim().isEmpty
                  ? label('نتائج التحليل', 'Analysis results')
                  : result.title,
            ),
            metadata(
              label('تاريخ التقرير', 'Report date'),
              ReportPresentation.date(reportTimestamp ?? result.createdAt),
            ),
            if (patientName != null && patientName.trim().isNotEmpty)
              metadata(label('الاسم', 'Name'), patientName),
            metadata(
              label('نوع التحليل', 'Analysis target'),
              ReportPresentation.target(result, isArabic),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: cream,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: borderColor),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  metadata(
                    label('الدرجة الإجمالية', 'Overall score'),
                    ReportPresentation.score(result.overallScore),
                  ),
                  metadata(
                    label('أولوية الحالة', 'Case priority'),
                    ReportPresentation.priority(result.urgency, isArabic),
                  ),
                  metadata(
                    label('جودة الصورة', 'Image quality'),
                    ReportPresentation.imageQuality(
                      result.imageQualityByLang(lang),
                      isArabic,
                    ),
                  ),
                  metadata(
                    label('ثقة التحليل المرسلة', 'Reported AI confidence'),
                    ReportPresentation.text(result.aiConfidence),
                  ),
                ],
              ),
            ),
            heading(label('المقاييس', 'Measurements')),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ReportPresentation.metrics(result, isArabic).entries
                  .map((entry) => metricTile(entry.key, entry.value))
                  .toList(),
            ),
            metadata(
              label('مراجعة الطبيب', 'Doctor review'),
              result.shouldSeeDoctor
                  ? label('يُنصح بالمراجعة', 'Advised')
                  : label(
                      'لم تُطلب في هذا التقرير',
                      'Not requested in this report',
                    ),
            ),
          ],
        ),
      ),
    );

    // Keep the executive result page complete. The detailed advice always
    // begins on a clean page instead of being split through a card boundary.
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        header: (context) => reportHeader(compact: true),
        footer: (context) => pw.Text(
          '${context.pageNumber} / ${context.pagesCount}',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: regularFont, fontSize: 9, color: mutedText),
        ),
        build: (context) => [
          heading(label('ملخص التحليل', 'Analysis summary')),
          paragraph(result.summaryByLang(lang)),
          ...steps(
            label('الملاحظات المرئية', 'Visible findings'),
            result.visibleFindingsByLang(lang),
          ),
          ...steps(
            label('أسباب المتابعة', 'Follow-up reasons'),
            result.reasonsByLang(lang),
          ),
          ...steps(
            label('روتين صباحي', 'Morning routine'),
            result.morningRoutine,
            showEmpty: true,
          ),
          ...steps(
            label('روتين مسائي', 'Evening routine'),
            result.eveningRoutine,
            showEmpty: true,
          ),
          ...steps(
            label('العناية العامة', 'General care'),
            result.careStepsByLang(lang),
          ),
          ...catalog(
            label('منتجات من الدليل', 'Catalog products'),
            result.products,
            doctors: false,
          ),
          ...catalog(
            label('أطباء من الدليل', 'Catalog doctors'),
            result.doctors,
            doctors: true,
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: borderColor, thickness: 0.8),
          paragraph(
            result.disclaimerByLang(lang).trim().isEmpty
                ? label(
                    'هذا التقرير استرشادي وليس تشخيصًا طبيًا. راجع طبيبًا عند الحاجة.',
                    'This report is informational, not a medical diagnosis. Consult a physician when needed.',
                  )
                : result.disclaimerByLang(lang),
          ),
        ],
      ),
    );
    return pdf.save();
  }
}
