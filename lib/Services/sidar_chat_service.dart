import 'package:supabase_flutter/supabase_flutter.dart';

enum SidarChatRole { user, assistant }

class SidarChatMessage {
  const SidarChatMessage({required this.role, required this.text});

  final SidarChatRole role;
  final String text;

  Map<String, String> toRequest() => {
    'role': role == SidarChatRole.user ? 'user' : 'assistant',
    'content': text,
  };
}

/// Keeps the AI provider credentials on the server. The mobile app only calls
/// the authenticated `sidar-chat` Edge Function.
class SidarChatService {
  SidarChatService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String> send({
    required String message,
    required bool isArabic,
    required List<SidarChatMessage> history,
  }) async {
    final text = message.trim();
    if (text.isEmpty) {
      throw ArgumentError(
        isArabic ? 'اكتب رسالتك أولاً.' : 'Write a message first.',
      );
    }
    if (text.length > 1200) {
      throw ArgumentError(
        isArabic
            ? 'الرسالة طويلة جدًا. الحد الأقصى 1200 حرف.'
            : 'Your message is too long. The limit is 1200 characters.',
      );
    }

    var session = _client.auth.currentSession;
    if (session == null) {
      throw Exception(
        isArabic
            ? 'سجل الدخول لاستخدام مساعد سدر.'
            : 'Please sign in to use the SIDAR assistant.',
      );
    }
    if (session.isExpired) {
      session = (await _client.auth.refreshSession()).session;
    }
    if (session == null) {
      throw Exception(
        isArabic ? 'يرجى تسجيل الدخول مرة أخرى.' : 'Please sign in again.',
      );
    }

    try {
      final response = await _client.functions.invoke(
        'sidar-chat',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        body: {
          'message': text,
          'language': isArabic ? 'ar' : 'en',
          'history': history
              .where((entry) => entry.text.trim().isNotEmpty)
              .take(10)
              .map((entry) => entry.toRequest())
              .toList(),
        },
      );
      final data = response.data;
      if (data is Map) {
        final reply = data['reply']?.toString().trim() ?? '';
        if (reply.isNotEmpty) return reply;
        final error = data['error']?.toString().trim() ?? '';
        if (error.isNotEmpty) throw Exception(error);
      }
      throw Exception(
        isArabic
            ? 'تعذر الحصول على رد من المساعد الآن.'
            : 'The assistant could not respond right now.',
      );
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] != null) {
        throw Exception(details['error'].toString());
      }
      throw Exception(
        isArabic
            ? 'تعذر الاتصال بالمساعد. حاول مرة أخرى.'
            : 'Unable to contact the assistant. Please try again.',
      );
    }
  }
}
