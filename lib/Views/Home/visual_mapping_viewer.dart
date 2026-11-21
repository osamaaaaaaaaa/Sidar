import 'package:flutter/material.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';

/// Renders only visual evidence returned by the analysis provider. A map never
/// falls back to generated artwork: unavailable provider assets stay explicit.
class VisualMappingViewer extends StatefulWidget {
  const VisualMappingViewer({
    super.key,
    required this.assets,
    required this.metrics,
    required this.isArabic,
  });

  final List<Map<String, dynamic>> assets;
  final Map<String, double?> metrics;
  final bool isArabic;

  @override
  State<VisualMappingViewer> createState() => _VisualMappingViewerState();
}

class _VisualMappingViewerState extends State<VisualMappingViewer> {
  String _kind = 'original';
  String? _metric;
  bool _compare = false;

  String _label(String ar, String en) => widget.isArabic ? ar : en;

  List<Map<String, dynamic>> get _available => widget.assets.where((asset) {
    final url = (asset['url'] ?? asset['signed_url'] ?? '').toString();
    return url.startsWith('https://') || url.startsWith('http://');
  }).toList();

  List<String> get _metricIds {
    final values = _available
        .map((asset) => asset['metric_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty && id != 'original')
        .toSet()
        .toList();
    values.sort();
    return values;
  }

  Map<String, dynamic>? _asset(String kind, String? metric) {
    final exact = _available.where(
      (asset) =>
          asset['asset_type']?.toString() == kind &&
          (metric == null || asset['metric_id']?.toString() == metric),
    );
    if (exact.isNotEmpty) return exact.first;
    if (kind == 'original') {
      final original = _available.where(
        (asset) => asset['asset_type']?.toString() == 'original',
      );
      if (original.isNotEmpty) return original.first;
    }
    return null;
  }

  String _metricName(String id) => switch (id) {
    'hd_pore' => _label('المسام', 'Pores'),
    'hd_wrinkle' => _label('الخطوط الدقيقة', 'Fine lines'),
    'hd_redness' => _label('الاحمرار', 'Redness'),
    'hd_acne' => _label('الشوائب', 'Blemishes'),
    'hd_oiliness' => _label('المظهر الدهني', 'Oiliness'),
    'hd_texture' => _label('ملمس البشرة', 'Texture'),
    _ => id.replaceAll('hd_', '').replaceAll('_', ' '),
  };

  double? _score(String? id) => switch (id) {
    'hd_pore' => widget.metrics['pore'],
    'hd_wrinkle' => widget.metrics['lines'],
    'hd_redness' => widget.metrics['tone'],
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final original = _asset('original', null);
    if (_available.isEmpty || original == null) return _unavailableCard();
    _metric ??= _metricIds.isEmpty ? null : _metricIds.first;
    final selected = _kind == 'original' ? original : _asset(_kind, _metric);
    return AppTheme.glassPanel(
      borderRadius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.layers_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _label('خريطة التحليل البصرية', 'Visual analysis map'),
                  style: AppTheme.headingStyle(fontSize: 18),
                ),
              ),
              if (_metricIds.isNotEmpty)
                IconButton(
                  tooltip: _label('مقارنة', 'Compare'),
                  onPressed: () => setState(() => _compare = !_compare),
                  icon: Icon(
                    _compare ? Icons.compare : Icons.compare_outlined,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                const [
                  ('original', 'Original', 'الأصلية'),
                  ('overlay', 'Overlay', 'الطبقة'),
                  ('heatmap', 'Heatmap', 'خريطة الحرارة'),
                  ('mask', 'Mask', 'القناع'),
                ].map((item) {
                  final enabled =
                      item.$1 == 'original' || _asset(item.$1, _metric) != null;
                  return ChoiceChip(
                    label: Text(widget.isArabic ? item.$3 : item.$2),
                    selected: _kind == item.$1,
                    onSelected: enabled
                        ? (_) => setState(() => _kind = item.$1)
                        : null,
                  );
                }).toList(),
          ),
          if (_metricIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _metric,
              decoration: InputDecoration(
                labelText: _label('المقياس', 'Metric'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _metricIds
                  .map(
                    (id) => DropdownMenuItem(
                      value: id,
                      child: Text(_metricName(id)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _metric = value),
            ),
          ],
          const SizedBox(height: 14),
          _imagePanel(original, selected),
          if (_metric != null) ...[
            const SizedBox(height: 12),
            _metricCard(_metric!),
          ],
        ],
      ),
    );
  }

  Widget _imagePanel(
    Map<String, dynamic> original,
    Map<String, dynamic>? selected,
  ) {
    final selectionUrl = (selected?['url'] ?? selected?['signed_url'] ?? '')
        .toString();
    final originalUrl = (original['url'] ?? original['signed_url'] ?? '')
        .toString();
    if (selected == null || selectionUrl.isEmpty) {
      return _assetUnavailable(
        _label(
          'هذه الخريطة غير متاحة لهذا المقياس.',
          'This map is unavailable for this metric.',
        ),
      );
    }
    Widget image(String url) => InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _assetUnavailable(
          _label('تعذر تحميل الخريطة.', 'The map could not be loaded.'),
        ),
      ),
    );
    // A fixed viewport avoids passing an unbounded scroll height into
    // InteractiveViewer while the network image is resolving.
    return SizedBox(
      height: 280,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: _compare && _kind != 'original'
            ? Row(
                children: [
                  Expanded(child: image(originalUrl)),
                  Expanded(child: image(selectionUrl)),
                ],
              )
            : image(selectionUrl),
      ),
    );
  }

  Widget _metricCard(String metric) {
    final score = _score(metric);
    final current = _asset(_kind, metric);
    final confidence = current?['confidence']?.toString();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.goldSoft.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _metricName(metric),
                  style: AppTheme.headingStyle(fontSize: 16),
                ),
                Text(
                  score == null
                      ? _label(
                          'القياس متاح، والدرجة غير متاحة.',
                          'Measurement available; score unavailable.',
                        )
                      : '${score.toStringAsFixed(0)} / 100',
                  style: AppTheme.bodyStyle(fontWeight: FontWeight.bold),
                ),
                if (confidence != null && confidence.isNotEmpty)
                  Text(
                    '${_label('موثوقية القياس', 'Measurement reliability')}: $confidence',
                  ),
              ],
            ),
          ),
          const Icon(Icons.info_outline, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _unavailableCard() => _assetUnavailable(
    _label(
      'الخرائط البصرية ستظهر هنا عندما يعيدها مزود التحليل. لا نعرض خرائط مولّدة بدل النتائج الأصلية.',
      'Visual maps appear here when returned by the analysis provider. No generated maps are used as evidence.',
    ),
  );
  Widget _assetUnavailable(String message) => Container(
    alignment: Alignment.center,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.goldSoft.withValues(alpha: .25),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTheme.bodyStyle(fontSize: 13),
        ),
      ],
    ),
  );
}
