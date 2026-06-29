import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:skincare/Models/ScanAiModel.dart';
import 'package:skincare/Services/ScanAiServices.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> webResponse() => {
  'title': ' Visible dryness ',
  'analysis_target': 'skin',
  'ai_confidence': ' 88% ',
  'case_priority': 'High',
  'image_quality': 'Good',
  'visible_patterns': [' Dry patches ', 'Redness'],
  'guidance': ' Use gentle care. ',
  'next_steps': ['Cleanse gently', 'Consult a dermatologist'],
  'reasons': ['Persistent redness', 'Visible irritation'],
  'overall_score': 76,
  'hydration_score': 63,
  'pore_clarity_score': 81,
  'fine_lines_score': 84,
  'overall_tone_score': 72,
  'morning_routine': ['Cleanse', 'Moisturize', 'Use sunscreen'],
  'evening_routine': ['Cleanse', 'Moisturize', 'Avoid irritants'],
  'suggested_product_ids': <String>[],
  'suggested_doctor_ids': <String>[],
  'disclaimer': ' Educational guidance, not a diagnosis. ',
};

Map<String, dynamic> product(
  String id, {
  String name = 'Gentle cleanser',
  String category = 'skin',
  List<String> concerns = const [],
  List<String> skinTypes = const [],
}) => {
  'id': id,
  'name': name,
  'brand': 'SIDAR',
  'description': 'A gentle daily cleansing product.',
  'is_active': true,
  'category': category,
  'concerns': concerns,
  'skin_types': skinTypes,
  'price': 18.5,
  'image_url':
      'https://catalog.example/storage/v1/object/public/sidar_images/$id.png',
  'product_url': 'https://catalog.example/products/$id',
};

Map<String, dynamic> doctor(
  String id, {
  String country = 'Egypt',
  String city = 'Cairo',
}) => {
  'id': id,
  'full_name': 'Dr Verified',
  'specialization': 'Dermatology',
  'country': country,
  'city': city,
  'clinic_hospital': 'Verified Clinic',
  'booking_url': 'https://clinic.example/book/$id',
  'is_verified': true,
  'status': 'Active',
};

List<String> ids(dynamic records) =>
    (records as List).map((item) => (item as Map)['id'] as String).toList();

void main() {
  group('ScanAiResult website and historical contract', () {
    test('maps fresh website fields and leaves absent scores null', () {
      final result = ScanAiResult.fromJson(webResponse());
      expect(result.title, 'Visible dryness');
      expect(result.summary, 'Use gentle care.');
      expect(result.visibleFindings, ['Dry patches', 'Redness']);
      expect(result.careSteps, ['Cleanse gently', 'Consult a dermatologist']);
      expect(result.urgency, 'high');
      expect(result.shouldSeeDoctor, isTrue);
      expect(result.aiConfidence, '88%');
      expect(result.overallScore, 76.0);
      expect(result.hydrationScore, 63.0);
      expect(result.hairDensityScore, isNull);
      expect(result.createdAt, isNull);
    });

    test(
      'nullable row text aliases fall back within the row, not to raw text',
      () {
        final result = ScanAiResult.fromJson({
          'report_title': null,
          'title': 'Legacy row title',
          'summary': '',
          'problem_description': 'Persisted guidance',
          'disclaimer': '',
          'raw_ai_response': {
            'title': 'Stale title',
            'summary': 'Stale summary',
            'disclaimer': 'Stale disclaimer',
          },
        });
        expect(result.title, 'Legacy row title');
        expect(result.summary, 'Persisted guidance');
        expect(result.disclaimer, '');
      },
    );

    test('partial raw response cannot erase persisted website row fields', () {
      final result = ScanAiResult.fromJson({
        'report_title': 'Saved title',
        'summary': 'Saved guidance',
        'urgency': 'HIGH',
        'visible_findings': ['Saved finding'],
        'care_steps': ['Saved step'],
        'image_quality': 'Good',
        'overall_score': 82,
        'raw_ai_response': {'summary': '', 'location_text': 'eg'},
      });
      expect(result.title, 'Saved title');
      expect(result.summary, 'Saved guidance');
      expect(result.urgency, 'high');
      expect(result.shouldSeeDoctor, isTrue);
      expect(result.visibleFindings, ['Saved finding']);
      expect(result.careSteps, ['Saved step']);
      expect(result.overallScore, 82);
    });

    test('persisted aliases take precedence before any raw aliases', () {
      final result = ScanAiResult.fromJson({
        'summary': 'Saved',
        'urgency': 'HIGH',
        'visible_findings': ['Persisted'],
        'care_steps': [],
        'overall_score': null,
        'commercial_product_suggestions': [],
        'raw_ai_response': {
          ...webResponse(),
          'case_priority': 'Low',
          'visibleFindings': ['Old mobile'],
          'careSteps': ['Stale care'],
          'commercial_product_suggestions': [
            {'id': 'old', 'name': 'Stale'},
          ],
        },
      });
      expect(result.summary, 'Saved');
      expect(result.urgency, 'high');
      expect(result.visibleFindings, ['Persisted']);
      expect(result.careSteps, isEmpty);
      expect(result.overallScore, isNull);
      expect(result.products, isEmpty);
      expect(result.morningRoutine, ['Cleanse', 'Moisturize', 'Use sunscreen']);
    });

    test('reads bilingual raw mobile records with snake and camel aliases', () {
      final result = ScanAiResult.fromJson({
        'raw_ai_response': {
          'summary': 'Original',
          'summary_ar': 'الملخص',
          'visibleFindings': ['Finding'],
          'visible_findings_ar': ['ملاحظة'],
          'careSteps': ['Care'],
          'care_steps_ar': ['عناية'],
          'reasons': ['Reason'],
          'reasons_ar': ['سبب'],
          'imageQuality': 'Clear image',
          'image_quality_ar': 'صورة واضحة',
          'disclaimer': 'Not a diagnosis',
          'disclaimer_ar': 'ليس تشخيصًا',
          'urgency': 'medium',
          'shouldSeeDoctor': true,
        },
      });
      expect(result.summaryByLang('ar-EG'), 'الملخص');
      expect(result.summaryByLang('en'), 'Original');
      expect(result.visibleFindingsByLang('ar'), ['ملاحظة']);
      expect(result.visibleFindingsByLang('en'), ['Finding']);
      expect(result.careStepsByLang('ar'), ['عناية']);
      expect(result.reasonsByLang('ar'), ['سبب']);
      expect(result.imageQualityByLang('ar'), 'صورة واضحة');
      expect(result.disclaimerByLang('ar'), 'ليس تشخيصًا');
      expect(result.shouldSeeDoctor, isTrue);
    });

    test('missing or empty locale lists do not mask primary data', () {
      final result = ScanAiResult.fromJson({
        ...webResponse(),
        'visible_findings_ar': [],
        'care_steps_en': ['  '],
        'reasons_ar': null,
      });
      expect(result.visibleFindingsAr, isNull);
      expect(result.visibleFindingsByLang('ar'), result.visibleFindings);
      expect(result.visibleFindingsByLang('en'), result.visibleFindings);
      expect(result.careStepsByLang('en'), result.careSteps);
      expect(result.reasonsByLang('ar'), result.reasons);
    });

    test(
      'legacy constructor defaults and empty locale fallback remain compatible',
      () {
        const result = ScanAiResult(
          summary: 'Summary',
          visibleFindings: ['Finding'],
          careSteps: ['Care'],
          urgency: 'low',
          shouldSeeDoctor: false,
          reasons: ['Reason'],
          imageQuality: 'Good',
          disclaimer: 'Educational',
          visibleFindingsAr: [],
          summaryEn: '',
        );
        expect(result.title, '');
        expect(result.analysisTarget, 'skin');
        expect(result.aiConfidence, '');
        expect(result.overallScore, isNull);
        expect(result.products, isEmpty);
        expect(result.doctors, isEmpty);
        expect(result.morningRoutine, isEmpty);
        expect(result.eveningRoutine, isEmpty);
        expect(result.visibleFindingsByLang('ar'), ['Finding']);
        expect(result.summaryByLang('en'), 'Summary');
      },
    );

    test('round-trips every shared field through canonical row JSON', () {
      final result = ScanAiResult.fromJson({
        ...webResponse(),
        'analysis_target': 'both',
        'hair_density_score': 65,
        'hair_texture_score': 66,
        'hair_strength_score': 67,
        'scalp_health_score': 68,
        'summary_ar': 'ملخص',
        'commercial_product_suggestions': [
          {'id': 'product', 'name': 'Stored product'},
        ],
        'nearby_doctors': [
          {'id': 'doctor', 'name': 'Stored doctor'},
        ],
        'created_at': '2026-06-01T12:34:00Z',
      });
      final row = result.toJson();
      expect(row['summary'], result.summary);
      expect(row['visible_findings'], result.visibleFindings);
      expect(row['care_steps'], result.careSteps);
      expect(row['urgency'], 'high');
      expect(row['overall_score'], 76);
      expect(row['summary_ar'], 'ملخص');
      expect(row.containsKey('case_priority'), isFalse);
      expect(row.containsKey('visible_patterns'), isFalse);
      expect(row.containsKey('guidance'), isFalse);
      expect(row.containsKey('next_steps'), isFalse);
      expect(row.containsKey('overallScore'), isFalse);
      expect(ScanAiResult.fromJson(row).toJson(), row);
      expect(result.createdAt, DateTime.utc(2026, 6, 1, 12, 34));
    });

    test(
      'invalid/missing historical scores stay null, zero is a real score',
      () {
        final result = ScanAiResult.fromJson({
          'overall_score': 'invalid',
          'hydration_score': null,
          'pore_clarity_score': '',
          'fine_lines_score': 0,
          'overall_tone_score': '91.5',
          'hair_density_score': double.nan,
          'hair_texture_score': true,
          'hair_strength_score': 120,
        });
        expect(result.overallScore, isNull);
        expect(result.hydrationScore, isNull);
        expect(result.poreClarityScore, isNull);
        expect(result.hairDensityScore, isNull);
        expect(result.hairTextureScore, isNull);
        expect(result.scalpHealthScore, isNull);
        expect(result.fineLinesScore, 0);
        expect(result.overallToneScore, 91.5);
        expect(result.hairStrengthScore, 100);
      },
    );

    test(
      'infers legacy hair target and drops id-less generated suggestions',
      () {
        final result = ScanAiResult.fromJson({
          'scan_type': 'scalp_check',
          'commercial_product_suggestions': [
            {'name': 'Invented'},
          ],
          'nearby_doctors': [
            {'name': 'Invented'},
          ],
        });
        expect(result.analysisTarget, 'hair');
        expect(result.products, isEmpty);
        expect(result.doctors, isEmpty);
      },
    );
  });

  group('Fresh response validation and catalog resolution', () {
    test(
      'normalizes required fields without Supabase or Firebase initialization',
      () {
        final result = ScanAiService.parseResponse(webResponse());
        expect(result.summary, 'Use gentle care.');
        expect(result.title, 'Visible dryness');
        expect(result.urgency, 'high');
        expect(result.shouldSeeDoctor, isTrue);
        expect(result.products, isEmpty);
        expect(result.doctors, isEmpty);
        expect(result.hairDensityScore, isNull);
      },
    );

    test('rejects invalid response shapes and empty required text', () {
      for (final payload in [null, [], 'not JSON', 5]) {
        expect(
          () => ScanAiService.parseResponse(payload),
          throwsFormatException,
        );
      }
      for (final key in ['title', 'guidance', 'ai_confidence', 'disclaimer']) {
        for (final value in [null, '', '  ', 42]) {
          expect(
            () => ScanAiService.parseResponse({...webResponse(), key: value}),
            throwsFormatException,
            reason: '$key: $value',
          );
        }
      }
    });

    test('requires usable string arrays and enforces website item caps', () {
      for (final key in [
        'visible_patterns',
        'next_steps',
        'reasons',
        'morning_routine',
        'evening_routine',
      ]) {
        for (final value in [
          null,
          [],
          [' '],
          [42],
          'not an array',
        ]) {
          expect(
            () => ScanAiService.parseResponse({...webResponse(), key: value}),
            throwsFormatException,
            reason: '$key: $value',
          );
        }
        final result = ScanAiService.parseResponse({
          ...webResponse(),
          key: List.generate(8, (index) => 'Item $index'),
        });
        final values = switch (key) {
          'visible_patterns' => result.visibleFindings,
          'next_steps' => result.careSteps,
          'reasons' => result.reasons,
          'morning_routine' => result.morningRoutine,
          _ => result.eveningRoutine,
        };
        expect(values.length, key == 'reasons' ? 4 : 5);
      }
    });

    test('uses website enum fallbacks rather than trusting unknown values', () {
      final result = ScanAiService.parseResponse({
        ...webResponse(),
        'analysis_target': 'invalid',
        'case_priority': 'invalid',
        'image_quality': 'invalid',
      });
      expect(result.analysisTarget, 'skin');
      expect(result.urgency, 'medium');
      expect(result.shouldSeeDoctor, isFalse);
      expect(result.imageQuality, 'Medium');
      expect(
        ScanAiService.parseResponse({
          ...webResponse(),
          'case_priority': 'Low',
        }).urgency,
        'low',
      );
    });

    test(
      'validates overall score and normalizes optional/non-applicable scores',
      () {
        for (final value in [
          null,
          '',
          'bad',
          double.infinity,
          double.nan,
          true,
        ]) {
          expect(
            () => ScanAiService.parseResponse({
              ...webResponse(),
              'overall_score': value,
            }),
            throwsFormatException,
          );
        }
        final result = ScanAiService.parseResponse({
          ...webResponse(),
          'overall_score': '120',
          'hydration_score': -2,
          'pore_clarity_score': 'bad',
          'fine_lines_score': null,
          'hair_density_score': 0,
        });
        expect(result.overallScore, 100);
        expect(result.hydrationScore, 0);
        expect(result.poreClarityScore, isNull);
        expect(result.fineLinesScore, isNull);
        expect(result.hairDensityScore, 0);
        expect(result.hairTextureScore, isNull);
        final hair = ScanAiService.parseResponse({
          ...webResponse()
            ..remove('hydration_score')
            ..remove('pore_clarity_score')
            ..remove('fine_lines_score')
            ..remove('overall_tone_score'),
          'analysis_target': 'hair',
          'hair_density_score': 82,
        });
        expect(hair.hydrationScore, isNull);
        expect(hair.hairDensityScore, 82);
      },
    );

    test('resolves selected IDs only and discards model presentation data', () {
      final catalog = ScanAiService.filterCatalog(
        products: [product('p1'), product('p2')],
        doctors: [
          doctor('d1'),
          doctor('foreign', country: 'Saudi Arabia', city: 'Riyadh'),
        ],
        context: {'location_text': 'Cairo'},
      );
      final result = ScanAiService.parseResponse({
        ...webResponse(),
        'suggested_product_ids': ['fake', 'p2', 'p2'],
        'suggested_doctor_ids': ['foreign', 'd1'],
        'commercial_product_suggestions': [
          {'id': 'p2', 'name': 'Invented product', 'price': '\$0'},
        ],
        'natural_product_suggestions': [
          {'name': 'Invented natural product'},
        ],
        'nearby_doctors': [
          {'id': 'd1', 'name': 'Invented doctor'},
        ],
      }, catalog: catalog);
      expect(ids(result.products), ['p2']);
      expect(result.products.single['name'], 'SIDAR Gentle cleanser');
      expect(result.products.single['price'], '\$18.50');
      expect(result.products.single['image'], product('p2')['image_url']);
      expect(result.products.single['link'], product('p2')['product_url']);
      expect(ids(result.doctors), ['d1']);
      expect(result.doctors.single['name'], 'Dr Verified');
      expect(result.doctors.single['specialty'], 'Dermatology');
      expect(result.doctors.single['link'], doctor('d1')['booking_url']);
      expect(result.toJson()['natural_product_suggestions'], isEmpty);
    });

    test(
      'unknown/missing selections fall back to first four filtered records',
      () {
        final catalog = ScanAiService.filterCatalog(
          products: List.generate(
            6,
            (index) => product('p$index', name: 'Product $index'),
          ),
          doctors: List.generate(6, (index) => doctor('d$index')),
          context: {'location_text': 'eg'},
        );
        final result = ScanAiService.parseResponse({
          ...webResponse(),
          'suggested_product_ids': ['unknown'],
          'suggested_doctor_ids': null,
        }, catalog: catalog);
        expect(ids(result.products), ['p0', 'p1', 'p2', 'p3']);
        expect(ids(result.doctors), ['d0', 'd1', 'd2', 'd3']);
        final empty = ScanAiService.parseResponse({
          ...webResponse(),
          'suggested_product_ids': ['unknown'],
          'commercial_product_suggestions': [
            {'name': 'Invented'},
          ],
        });
        expect(empty.products, isEmpty);
        expect(empty.doctors, isEmpty);
      },
    );

    test('preserves safe endpoint error messages', () {
      final error = FunctionException(
        status: 429,
        details: {
          'error': 'Analysis limit reached. Please try again in an hour.',
        },
      );
      expect(
        ScanAiService.functionErrorMessage(error),
        'Analysis limit reached. Please try again in an hour.',
      );
      expect(
        ScanAiService.functionErrorMessage(
          FunctionException(
            status: 500,
            details: {'debug': 'internal details'},
          ),
        ),
        'Unable to complete the analysis request.',
      );
      expect(
        () => ScanAiService.parseResponse({'error': 'Please sign in again.'}),
        throwsA(
          predicate(
            (error) => error.toString().contains('Please sign in again.'),
          ),
        ),
      );
    });
  });

  group('Verified catalog filters', () {
    test(
      'checks product completeness, active state and verified image storage',
      () {
        final catalog = ScanAiService.filterCatalog(
          products: [
            product('valid'),
            {...product('inactive'), 'is_active': false},
            {...product('nameless'), 'name': 'x'},
            {...product('brandless'), 'brand': ''},
            {...product('short'), 'description': 'short'},
            {
              ...product('external'),
              'image_url': 'https://random.example/product.png',
            },
            {
              ...product('wrongbucket'),
              'image_url':
                  'https://catalog.example/storage/v1/object/public/other/file.png',
            },
            {...product('emptyid'), 'id': ''},
            {
              ...product('medical'),
              'description': '',
              'medical_description': 'Verified medical description.',
            },
          ],
          doctors: [],
        );
        expect(ids(catalog['products']), ['valid', 'medical']);
      },
    );

    test(
      'ranks scope, concerns and skin type without mutating catalog input',
      () {
        final source = [
          product('plain', name: 'Alpha'),
          product(
            'relevant',
            name: 'Zulu',
            concerns: ['dryness'],
            skinTypes: ['dry'],
          ),
          product('hair', category: 'hair'),
          product('both', category: 'both', name: 'Beta'),
        ];
        final before = jsonEncode(source);
        final catalog = ScanAiService.filterCatalog(
          products: source,
          doctors: [],
          context: {
            'scan_type': 'skin_check',
            'issue_type': 'dryness',
            'skin_type_context': 'dry',
          },
        );
        expect(ids(catalog['products']), ['relevant', 'plain', 'both']);
        expect(jsonEncode(source), before);
      },
    );

    test(
      'empty concern and skin type entries cannot boost out-of-scope products',
      () {
        final catalog = ScanAiService.filterCatalog(
          products: [
            {
              ...product('skin'),
              'concerns': [''],
              'skin_types': null,
              'skin_type': '',
            },
            product('hair', category: 'hair'),
            product('both', category: 'both'),
          ],
          doctors: [],
          context: {'scan_type': 'scalp_check', 'issue_type': 'hair_loss'},
        );
        expect(ids(catalog['products']), ['hair', 'both']);
        expect((catalog['location'] as Map)['target'], 'hair');
      },
    );

    test(
      'Arabic and city aliases match local country, never blank foreign cities',
      () {
        final doctors = [
          doctor('local'),
          doctor('arabic', country: 'مصر', city: 'القاهرة'),
          doctor('local-empty-city', city: ''),
          doctor('city-only', country: '', city: 'Giza'),
          doctor('foreign-empty-city', country: 'Saudi Arabia', city: ''),
          doctor('foreign', country: 'Saudi Arabia', city: 'Riyadh'),
          doctor('blank', country: '', city: ''),
        ];
        for (final location in ['eg', 'Cairo, Egypt', 'القاهرة، مصر', 'Giza']) {
          final catalog = ScanAiService.filterCatalog(
            products: [],
            doctors: doctors,
            context: {'location_text': location},
          );
          expect(ids(catalog['doctors']), [
            'local',
            'arabic',
            'local-empty-city',
            'city-only',
          ]);
          expect((catalog['location'] as Map)['countryCode'], 'eg');
        }
      },
    );

    test(
      'country aliases use whole phrases, not substrings like sa in USA',
      () {
        final catalog = ScanAiService.filterCatalog(
          products: [],
          doctors: [
            doctor('us', country: 'United States', city: 'Boston'),
            doctor('sa', country: 'Saudi Arabia', city: 'Riyadh'),
          ],
          context: {'location_text': 'USA'},
        );
        expect(ids(catalog['doctors']), ['us']);
        expect((catalog['location'] as Map)['countryCode'], 'us');
        for (final location in ['', '   ', 'Unknown', 'Sahara', 'Belgium']) {
          expect(
            ScanAiService.filterCatalog(
              products: [],
              doctors: [doctor('d')],
              context: {'location_text': location},
            )['doctors'],
            isEmpty,
          );
        }
      },
    );

    test(
      'requires active verified complete doctors and valid contact scheme',
      () {
        final catalog = ScanAiService.filterCatalog(
          products: [],
          doctors: [
            doctor('valid'),
            {...doctor('unverified'), 'is_verified': false},
            {...doctor('inactive'), 'status': 'Inactive'},
            {...doctor('nameless'), 'full_name': 'x'},
            {...doctor('specialty'), 'specialization': ''},
            {...doctor('clinic'), 'clinic_hospital': ''},
            {...doctor('link'), 'booking_url': 'javascript:alert(1)'},
            {
              ...doctor('tel'),
              'booking_url': '',
              'contact_url': 'tel:+20123456789',
            },
            {...doctor('mail'), 'booking_url': 'mailto:clinic@example.com'},
          ],
          context: {'location_label': 'Egypt'},
        );
        expect(ids(catalog['doctors']), ['valid', 'tel', 'mail']);
      },
    );

    test('caps products at twenty and doctors at twelve', () {
      final catalog = ScanAiService.filterCatalog(
        products: List.generate(25, (index) => product('p$index')),
        doctors: List.generate(20, (index) => doctor('d$index')),
        context: {'location_text': 'eg'},
      );
      expect(catalog['products'], hasLength(20));
      expect(catalog['doctors'], hasLength(12));
    });
  });

  group('Endpoint request contract', () {
    test('encodes approved image MIME types using endpoint keys', () {
      final images = ScanAiService.prepareImages([
        for (final mime in ['image/jpeg', 'image/png', 'image/webp'])
          ScanImageInput(bytes: Uint8List.fromList([1, 2, 3]), mimeType: mime),
      ]);
      expect(images, [
        {'mimeType': 'image/jpeg', 'data': 'AQID'},
        {'mimeType': 'image/png', 'data': 'AQID'},
        {'mimeType': 'image/webp', 'data': 'AQID'},
      ]);
      expect(ScanAiService.inferMimeType('photo.jpg'), 'image/jpeg');
      expect(ScanAiService.inferMimeType('photo.png'), 'image/png');
      expect(ScanAiService.inferMimeType('photo.webp'), 'image/webp');
    });

    test('rejects zero/six images, empty bytes and unsupported MIME types', () {
      final image = ScanImageInput(bytes: Uint8List(3), mimeType: 'image/jpeg');
      expect(() => ScanAiService.prepareImages([]), throwsArgumentError);
      expect(
        () => ScanAiService.prepareImages(List.filled(6, image)),
        throwsArgumentError,
      );
      expect(ScanAiService.prepareImages(List.filled(5, image)), hasLength(5));
      expect(
        () => ScanAiService.prepareImages([
          ScanImageInput(bytes: Uint8List(0), mimeType: 'image/jpeg'),
        ]),
        throwsArgumentError,
      );
      for (final mime in [
        'image/gif',
        'image/heic',
        'image/jpg',
        'application/pdf',
      ]) {
        expect(
          () => ScanAiService.prepareImages([
            ScanImageInput(bytes: Uint8List(3), mimeType: mime),
          ]),
          throwsArgumentError,
        );
      }
    });

    test(
      'enforces individual 14 million and total 18 million base64 boundaries',
      () {
        ScanImageInput image(int bytes) =>
            ScanImageInput(bytes: Uint8List(bytes), mimeType: 'image/jpeg');
        expect(
          ScanAiService.prepareImages([image(10500000)]).single['data']!.length,
          14000000,
        );
        expect(
          () => ScanAiService.prepareImages([image(10500001)]),
          throwsArgumentError,
        );
        expect(
          ScanAiService.prepareImages([
            image(6750000),
            image(6750000),
          ]).fold<int>(0, (total, item) => total + item['data']!.length),
          18000000,
        );
        expect(
          () => ScanAiService.prepareImages([image(6750000), image(6750001)]),
          throwsArgumentError,
        );
      },
    );

    test(
      'prompt requests one language and only website fields/catalog metadata',
      () {
        final prompt = ScanAiService.buildPrompt(
          {
            'scan_type': 'hair_check',
            'body_location': 'scalp',
            'symptoms': ['hair_loss'],
            'duration': 'one_month',
            'severity': 'high',
            'issue_type': 'hair_loss',
            'skin_type_context': 'dry',
            'notes': 'Itching',
            'private_value': 'DO NOT INCLUDE',
          },
          'ar-EG',
          catalog: {
            'products': [
              {...product('p'), 'private_value': 'DO NOT INCLUDE'},
            ],
            'doctors': [
              {...doctor('d'), 'private_value': 'DO NOT INCLUDE'},
            ],
          },
        );
        expect(prompt, contains('Use Arabic only'));
        expect(prompt, isNot(contains('Use English only')));
        expect(prompt, isNot(contains('summary_ar')));
        expect(prompt, isNot(contains('visibleFindings')));
        expect(prompt, isNot(contains('DO NOT INCLUDE')));
        expect(prompt, contains('"analysis_target"'));
        expect(prompt, contains('"suggested_product_ids"'));
        expect(prompt, contains('"suggested_doctor_ids"'));
        expect(prompt, contains('"scan_type":"hair_check"'));
        expect(prompt, contains('"id":"p"'));
        expect(prompt, contains('"id":"d"'));
        expect(prompt.length, lessThanOrEqualTo(30000));
        expect(
          ScanAiService.buildPrompt({}, 'en'),
          contains('Use English only'),
        );
      },
    );
  });
}
