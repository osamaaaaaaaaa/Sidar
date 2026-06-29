import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:skincare/Services/scan_remote_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const userId = '11111111-1111-4111-8111-111111111111';
  const scanId = '22222222-2222-4222-8222-222222222222';
  late HttpServer server;
  late SupabaseClient client;
  late ScanRemoteSource remote;
  late List<String> requests;
  late List<Map<String, dynamic>> imageRows;
  late Map<String, dynamic> sessionRow;
  bool failFindings = false;

  setUp(() async {
    requests = [];
    imageRows = [];
    sessionRow = {'id': scanId, 'user_id': userId, 'scan_type': 'skin_check', 'urgency': 'high', 'image_urls': <String>[]};
    failFindings = false;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final path = request.uri.path;
      requests.add('${request.method} $path');
      final bytes = await request.fold<List<int>>([], (all, part) => all..addAll(part));
      dynamic body;
      try { body = jsonDecode(utf8.decode(bytes)); } catch (_) { body = null; }
      final response = request.response;
      response.headers.contentType = ContentType.json;
      void reply(dynamic data, [int status = 200]) {
        response.statusCode = status;
        response.write(jsonEncode(data));
        response.close();
      }
      if (path == '/auth/v1/token') {
        final token = '${base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'))}.${base64Url.encode(utf8.encode(jsonEncode({'sub': userId, 'aud': 'authenticated', 'role': 'authenticated', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})))}.test';
        reply({'access_token': token, 'refresh_token': 'test-refresh', 'expires_in': 3600, 'token_type': 'bearer', 'user': {'id': userId, 'aud': 'authenticated', 'email': 'local@example.test', 'created_at': '2026-01-01T00:00:00Z', 'app_metadata': {}, 'user_metadata': {}}});
      } else if (path.startsWith('/storage/v1/object/sign/')) {
        reply({'signedURL': '${path.replaceFirst('/storage/v1', '')}?token=local'});
      } else if (path == '/storage/v1/object/scan-images' && request.method == 'DELETE') {
        reply([]);
      } else if (path.startsWith('/storage/v1/object/')) {
        reply({'Key': path.replaceFirst('/storage/v1/object/', '')});
      } else if (path == '/rest/v1/scan_sessions') {
        if (request.method == 'POST') {
          sessionRow = {'id': scanId, ...Map<String, dynamic>.from(body as Map)};
          reply(sessionRow, 201);
        } else if (request.method == 'DELETE') {
          reply([]);
        } else {
          final single = request.headers.value('accept')?.contains('vnd.pgrst.object') == true;
          reply(single ? sessionRow : [sessionRow]);
        }
      } else if (path == '/rest/v1/scan_images') {
        if (request.method == 'POST') {
          imageRows = List<Map<String, dynamic>>.from(body as List);
          reply(imageRows, 201);
        } else {
          reply(imageRows);
        }
      } else if (path == '/rest/v1/scan_findings') {
        if (failFindings && request.method == 'POST') {
          reply({'message': 'Simulated child insert failure', 'code': 'TEST'}, 500);
        } else {
          reply([]);
        }
      } else {
        reply({'message': 'Unexpected route: $path'}, 404);
      }
    });
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'local-public-key', authOptions: const AuthClientOptions(autoRefreshToken: false));
    await client.auth.signInWithPassword(email: 'local@example.test', password: 'local-test-only');
    remote = ScanRemoteSource(client: client);
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test('private upload, website-shaped save, signed history and storage-first deletion', () async {
    final path = await remote.uploadImage(bytes: Uint8List.fromList([1, 2, 3]), fileName: '../skin image.png', mimeType: 'image/png');
    expect(path, startsWith('$userId/'));
    expect(path.substring(userId.length + 1), isNot(contains('/')));
    await remote.saveReport(payload: sessionRow, imagePaths: [path], findings: [{'title': 'Redness', 'severity': 'high'}]);
    expect(imageRows.single['image_path'], path);
    expect(imageRows.single['image_url'], path);
    expect(imageRows.single['scan_id'], scanId);
    final history = await remote.getScans();
    final imageUrl = (history.single['image_urls'] as List).single as String;
    expect(imageUrl, contains('/storage/v1/object/sign/scan-images/$userId/'));
    expect(imageUrl, endsWith('?token=local'));
    expect(history.single['urgency'], 'high');
    await remote.deleteScan(scanId);
    final storageDelete = requests.indexOf('DELETE /storage/v1/object/scan-images');
    final rowDelete = requests.indexOf('DELETE /rest/v1/scan_sessions');
    expect(storageDelete, greaterThan(-1));
    expect(rowDelete, greaterThan(storageDelete));
  });

  test('rejects cross-account report and image paths before writing', () async {
    final before = requests.length;
    await expectLater(remote.saveReport(payload: {...sessionRow, 'user_id': 'another-user'}, imagePaths: [], findings: []), throwsA(isA<AuthException>()));
    await expectLater(remote.removeImages(['another-user/private.png']), throwsA(isA<AuthException>()));
    expect(requests.length, before);
  });

  test('removes incomplete session when a finding insert fails', () async {
    failFindings = true;
    await expectLater(remote.saveReport(payload: sessionRow, imagePaths: ['$userId/test.png'], findings: [{'title': 'Redness'}]), throwsA(isA<PostgrestException>()));
    expect(requests, contains('DELETE /rest/v1/scan_sessions'));
  });
}
