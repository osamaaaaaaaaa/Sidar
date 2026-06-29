import 'package:flutter_test/flutter_test.dart';
import 'package:skincare/Services/profile_values.dart';

void main() {
  group('Canonical portal profile values', () {
    test('Arabic and English gender labels retain their meaning', () {
      for (final entry in {
        'ذكر': 'male',
        'أنثى': 'female',
        'انثى': 'female',
        'آخر': 'other',
        'أخرى': 'other',
        ' FEMALE ': 'female',
      }.entries) {
        expect(ProfileValues.gender(entry.key), entry.value);
      }
      expect(ProfileValues.gender(null), isNull);
      expect(ProfileValues.gender('unknown'), isNull);
    });

    test(
      'all legacy Arabic skin values canonicalize, not to normal by default',
      () {
        for (final entry in {
          'عادية': 'normal',
          'جافة': 'dry',
          'دهنية': 'oily',
          'مختلطة': 'combination',
          'حساسة': 'sensitive',
          'البشرة الدهنية': 'oily',
          'بشرة جافة': 'dry',
          'Oily Skin': 'oily',
          'combination_skin': 'combination',
        }.entries) {
          expect(ProfileValues.skinType(entry.key), entry.value);
        }
        expect(ProfileValues.skinType('unknown'), 'unknown');
        expect(ProfileValues.skinType(null), isNull);
      },
    );

    test(
      'existing Arabic choices normalize without replacing unrelated fields',
      () {
        expect(
          ProfileValues.canonicalStoredFields({
            'gender': 'أنثى',
            'skin_type': 'دهنية',
            'location_text': 'AE',
            'allergies': ['fragrance'],
            'sun_sensitive': false,
          }),
          {'gender': 'female', 'skin_type': 'oily'},
        );
        expect(
          ProfileValues.canonicalStoredFields({
            'gender': 'other',
            'skin_type': 'dry',
          }),
          isEmpty,
        );
        expect(
          ProfileValues.canonicalStoredFields({
            'gender': 'unknown',
            'skin_type': 'custom',
          }),
          isEmpty,
        );
      },
    );

    test(
      'countries match website selectable code set including popular PS',
      () {
        expect(ProfileValues.countries.length, 195);
        expect(
          ProfileValues.countries.toSet().length,
          ProfileValues.countries.length,
        );
        expect(ProfileValues.country(' sa '), 'SA');
        expect(ProfileValues.country('PS'), 'PS');
        expect(ProfileValues.country('ZZ'), isNull);
        expect(ProfileValues.country('Saudi Arabia'), isNull);
        expect(ProfileValues.country('السعودية'), isNull);
      },
    );
  });

  group('Profile validation', () {
    String? validate({
      String name = 'Sidar',
      String age = '',
      String? gender,
      String? skin = 'normal',
      String? country = 'SA',
    }) => ProfileValues.validateProfile(
      name: name,
      age: age,
      genderValue: gender,
      skin: skin,
      location: country,
    );

    test('age and gender are optional', () {
      expect(validate(), isNull);
      expect(validate(gender: ''), isNull);
      expect(validate(gender: 'other'), isNull);
    });
    test('name, country and skin are required', () {
      expect(validate(name: ' '), 'name');
      expect(validate(skin: null), 'skin');
      expect(validate(skin: ''), 'skin');
      expect(validate(country: null), 'country');
      expect(validate(country: 'ZZ'), 'country');
      expect(validate(gender: 'invalid'), 'gender');
    });
    test('age follows website integer 1–120 bounds', () {
      for (final age in ['', ' ', '1', '120', '28']) {
        expect(validate(age: age), isNull, reason: age);
      }
      for (final age in ['0', '-1', '121', '1.5', 'abc']) {
        expect(validate(age: age), 'age', reason: age);
      }
    });
  });

  group('Safe metadata backfill', () {
    test(
      'Google re-login preserves saved identity, skin, location and health',
      () {
        final saved = <String, dynamic>{
          'full_name': 'My chosen name',
          'gender': 'أنثى',
          'skin_type': 'دهنية',
          'location_text': 'AE',
          'preferred_language': 'ar',
          'age': 40,
          'allergies': ['fragrance'],
          'medications': 'keep',
          'sun_sensitive': false,
        };
        expect(
          ProfileValues.missingProfileFields(saved, {
            'full_name': 'Google name',
            'gender': 'male',
            'skin_type': 'normal',
            'location_text': 'US',
            'preferred_language': 'en',
            'age': 20,
            'allergies': 'replace',
            'medications': '',
            'sun_sensitive': true,
            'role': 'admin',
          }),
          isEmpty,
        );
        expect(saved['skin_type'], 'دهنية');
        expect(saved['sun_sensitive'], false);
      },
    );
    test(
      'confirmation metadata backfills missing fields and converts types',
      () {
        expect(
          ProfileValues.missingProfileFields(
            {'full_name': '', 'age': null},
            {
              'full_name': 'Name',
              'age': '28',
              'gender': 'أنثى',
              'skin_type': 'حساسة',
              'location_text': 'sa',
              'preferred_language': 'en',
              'sun_sensitive': false,
              'role': 'admin',
            },
          ),
          {
            'full_name': 'Name',
            'age': 28,
            'gender': 'female',
            'skin_type': 'sensitive',
            'location_text': 'SA',
            'preferred_language': 'en',
            'sun_sensitive': false,
          },
        );
      },
    );
    test('invalid metadata never manufactures a default skin/country', () {
      expect(
        ProfileValues.missingProfileFields({}, {
          'skin_type': 'unknown',
          'location_text': 'ZZ',
          'gender': 'unknown',
          'age': '121',
          'preferred_language': 'xx',
          'full_name': '',
        }),
        {'skin_type': 'unknown'},
      );
    });
  });

  test('password validation preserves leading and trailing spaces', () {
    expect(ProfileValues.validatePassword(' secret ', ' secret '), isNull);
    expect(ProfileValues.validatePassword(' secret ', 'secret'), 'match');
    expect(ProfileValues.validatePassword('short', 'short'), 'length');
  });

  test('account deletion accepts only explicitly supported phrases', () {
    for (final phrase in [
      'DELETE',
      'حذف',
      'delete my account',
      'حذف حسابي',
      ' DELETE MY ACCOUNT ',
    ]) {
      expect(ProfileValues.validDeletePhrase(phrase), isTrue);
    }
    for (final phrase in [
      '',
      'yes',
      'delete everything',
      'حذف الحساب',
      'DELETE!',
    ]) {
      expect(ProfileValues.validDeletePhrase(phrase), isFalse);
    }
  });

  group('Storage cleanup (in-memory callbacks, no backend)', () {
    test(
      'drains first page repeatedly without skipping any of 251 images',
      () async {
        final files = List.generate(251, (i) => 'owner/$i.jpg').toSet();
        files.add('other/keep.jpg');
        final removed = <String>[];
        var pages = 0;
        await drainOwnedImages(
          owner: 'owner',
          checkSession: () {},
          listFirstPage: (path) async {
            expect(path, 'owner');
            pages++;
            return files
                .where((f) => f.startsWith('$path/'))
                .take(100)
                .map((f) => (name: f.split('/').last, folder: false))
                .toList();
          },
          remove: (paths) async {
            removed.addAll(paths);
            files.removeAll(paths);
          },
        );
        expect(pages, 4);
        expect(removed.toSet().length, 251);
        expect(files, {'other/keep.jpg'});
      },
    );

    test('nested owned folders are drained too', () async {
      final files = {'owner/scan/image.jpg', 'owner/top.jpg', 'other/keep.jpg'};
      await drainOwnedImages(
        owner: 'owner',
        checkSession: () {},
        listFirstPage: (path) async {
          final children = <String, bool>{};
          for (final file in files.where((f) => f.startsWith('$path/'))) {
            final relative = file.substring(path.length + 1);
            children[relative.split('/').first] = relative.contains('/');
          }
          return children.entries
              .map((e) => (name: e.key, folder: e.value))
              .toList();
        },
        remove: (paths) async => files.removeAll(paths),
      );
      expect(files, {'other/keep.jpg'});
    });

    test(
      'cleanup errors propagate, preventing subsequent account deletion',
      () async {
        var rpcCalled = false;
        Future<void> operation() async {
          await drainOwnedImages(
            owner: 'owner',
            checkSession: () {},
            listFirstPage: (_) async => [(name: 'image.jpg', folder: false)],
            remove: (_) async => throw StateError('denied'),
          );
          rpcCalled = true;
        }

        await expectLater(operation(), throwsStateError);
        expect(rpcCalled, isFalse);
      },
    );

    test('stale session stops before removing files', () async {
      var checks = 0;
      var removed = false;
      await expectLater(
        drainOwnedImages(
          owner: 'owner',
          checkSession: () {
            if (++checks > 1) throw StateError('signed out');
          },
          listFirstPage: (_) async => [(name: 'image.jpg', folder: false)],
          remove: (_) async {
            removed = true;
          },
        ),
        throwsStateError,
      );
      expect(removed, isFalse);
    });

    test('no-progress listing fails rather than looping forever', () async {
      await expectLater(
        drainOwnedImages(
          owner: 'owner',
          checkSession: () {},
          listFirstPage: (_) async => [(name: 'image.jpg', folder: false)],
          remove: (_) async {},
        ),
        throwsStateError,
      );
    });
  });
}
