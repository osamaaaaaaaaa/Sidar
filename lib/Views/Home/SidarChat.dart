import 'package:flutter/material.dart';
import 'package:skincare/Services/sidar_chat_service.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';

class SidarChatView extends StatefulWidget {
  const SidarChatView({super.key});

  @override
  State<SidarChatView> createState() => _SidarChatViewState();
}

class _SidarChatViewState extends State<SidarChatView> {
  final _service = SidarChatService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  late final bool _isArabic;
  late final List<SidarChatMessage> _messages;
  var _isSending = false;

  @override
  void initState() {
    super.initState();
    _isArabic = AppTheme.isArabic;
    _messages = [
      SidarChatMessage(
        role: SidarChatRole.assistant,
        text: _isArabic
            ? 'أهلًا، أنا مساعد سِدر. أستطيع مساعدتك في فهم روتين العناية، نتائج الفحص، واختيار الخطوات اللطيفة المناسبة.'
            : 'Hi, I am SIDAR assistant. I can help you understand your routine, scan results, and gentle next steps.',
      ),
    ];
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? suggestedMessage]) async {
    if (_isSending) return;
    final message = (suggestedMessage ?? _inputController.text).trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(SidarChatMessage(role: SidarChatRole.user, text: message));
      _isSending = true;
      _inputController.clear();
    });
    _scrollToBottom();

    try {
      final reply = await _service.send(
        message: message,
        isArabic: _isArabic,
        history: _messages.take(_messages.length - 1).toList(),
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          SidarChatMessage(role: SidarChatRole.assistant, text: reply),
        );
      });
    } catch (error) {
      if (!mounted) return;
      final text = error.toString().replaceFirst('Exception: ', '');
      setState(() {
        _messages.add(
          SidarChatMessage(
            role: SidarChatRole.assistant,
            text: _isArabic
                ? 'تعذر إرسال الرسالة: $text'
                : 'Unable to send: $text',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final quickPrompts = _isArabic
        ? ['كيف أبدأ روتينًا بسيطًا؟', 'كيف أستعد للفحص؟', 'متى أراجع طبيبًا؟']
        : [
            'How do I start a simple routine?',
            'How do I prepare for a scan?',
            'When should I see a doctor?',
          ];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.primary,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.7),
                ),
              ),
              child: Image.asset('assets/images/sidar-emblem-clean.png'),
            ),
            const SizedBox(width: 9),
            Text(
              _isArabic ? 'مساعد سِدر' : 'SIDAR Assistant',
              style: AppTheme.headingStyle(fontSize: 20),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _notice(),
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: _messages.length + (_isSending ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == _messages.length) return _typingBubble();
                  return _messageBubble(_messages[index]);
                },
              ),
            ),
            if (_messages.length == 1) _quickPrompts(quickPrompts),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _notice() => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.sageTint,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.borderSoft),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _isArabic
                ? 'معلومات عامة للعناية وليست تشخيصًا طبيًا. في الأعراض الشديدة أو المستمرة، راجع طبيبًا.'
                : 'General care guidance only, not a medical diagnosis. Seek a clinician for severe or persistent symptoms.',
            style: AppTheme.bodyStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _quickPrompts(List<String> prompts) => SizedBox(
    height: 44,
    child: ListView.separated(
      reverse: _isArabic,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: prompts.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) => ActionChip(
        label: Text(prompts[index], style: AppTheme.bodyStyle(fontSize: 12)),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.55)),
        backgroundColor: Colors.white,
        onPressed: () => _send(prompts[index]),
      ),
    ),
  );

  Widget _messageBubble(SidarChatMessage message) {
    final isUser = message.role == SidarChatRole.user;
    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser ? null : Border.all(color: AppColors.borderSoft),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: AppTheme.bodyStyle(
            fontSize: 14,
            height: 1.55,
            color: isUser ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _typingBubble() => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            _isArabic ? 'سِدر يكتب...' : 'SIDAR is typing...',
            style: AppTheme.bodyStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _composer() => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: AppColors.borderSoft)),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _inputController,
            enabled: !_isSending,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            style: AppTheme.bodyStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: _isArabic ? 'اكتب رسالتك...' : 'Write a message...',
              hintStyle: AppTheme.bodyStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surfaceMuted,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: AppColors.borderSoft),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: AppColors.borderSoft),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: _isSending ? null : _send,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.sageTint,
          ),
          icon: const Icon(Icons.send_rounded),
        ),
      ],
    ),
  );
}
