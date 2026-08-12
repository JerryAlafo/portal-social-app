import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/states.dart';

class IaPortalScreen extends StatefulWidget {
  const IaPortalScreen({super.key});

  @override
  State<IaPortalScreen> createState() => _IaPortalScreenState();
}

class _IaPortalScreenState extends State<IaPortalScreen> {
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();

  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;

  static const _suggestions = [
    'Que anime me recomendas para começar?',
    'Quais os melhores manga de 2026?',
    'Quando é o próximo anime festival em Portugal?',
    'Recomenda-me um isekai com romance',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.get('/api/chat');
      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>? ?? [];
        setState(() {
          _messages = list
              .map((m) => ChatMessage(
                    id: (m['id'] ?? '').toString(),
                    role: m['role'] == 'assistant' ? MessageRole.assistant : MessageRole.user,
                    content: (m['content'] ?? '').toString(),
                    createdAt: (m['created_at'] ?? '').toString(),
                  ))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('IA_PORTAL_HISTORY_ERROR: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send(String text) async {
    final sanitized = text.trim().replaceAll(RegExp(r'<[^>]*>'), '').sliceSafe(0, 2000);
    if (sanitized.isEmpty || _sending) return;

    final userMessage = ChatMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: sanitized,
      createdAt: DateTime.now().toIso8601String(),
    );

    setState(() {
      _messages = List.from(_messages)..add(userMessage);
      _inputController.clear();
      _sending = true;
    });

    _focusNode.unfocus();
    _scrollToBottom();

    try {
      final res = await ApiClient.instance.post(
        '/api/chat/send',
        body: {
          'message': sanitized,
          'history': _messages
              .where((m) => !m.id.startsWith('temp-'))
              .map((m) => {'role': m.role == MessageRole.assistant ? 'assistant' : 'user', 'content': m.content})
              .toList(),
        },
      );

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['data'] != null) {
          final reply = ChatMessage(
            id: (data['data']['id'] ?? 'reply-${DateTime.now().millisecondsSinceEpoch}').toString(),
            role: MessageRole.assistant,
            content: (data['data']['content'] ?? '').toString(),
            createdAt: (data['data']['created_at'] ?? DateTime.now().toIso8601String()).toString(),
          );
          setState(() {
            _messages = List.from(_messages)..add(reply);
          });
        } else {
          _addError();
        }
      } else {
        _addError();
      }
    } catch (e) {
      debugPrint('IA_PORTAL_SEND_ERROR: $e');
      _addError();
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _addError() {
    setState(() {
      _messages = List.from(_messages)
        ..add(ChatMessage(
          id: 'error-${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.assistant,
          content: 'Desculpa, tive um problema ao processar a tua mensagem.',
          createdAt: DateTime.now().toIso8601String(),
        ));
    });
  }

  Future<void> _clearChat() async {
    try {
      await ApiClient.instance.delete('/api/chat');
      setState(() => _messages = []);
    } catch (e) {
      debugPrint('IA_PORTAL_CLEAR_ERROR: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isGuest = auth.isGuest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('IA Portal'),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              onPressed: _clearChat,
              tooltip: 'Limpar conversa',
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: isGuest
          ? const EmptyView(
              message: 'Inicia sessão para usar o IA Portal.',
              icon: Icons.lock_outline,
            )
          : _loading
              ? const LoadingView(message: 'A carregar chat...')
              : _buildChat(),
    );
  }

  Widget _buildChat() {
    if (_messages.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.auto_awesome, size: 36, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'PORTAL Bot',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Especialista em anime e manga',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _suggestions
                          .map((s) => ActionChip(
                                label: Text(s, style: const TextStyle(fontSize: 12)),
                                onPressed: () => _send(s),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length + (_sending ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length) {
                return const _TypingIndicator();
              }
              final msg = _messages[index];
              return _MessageBubble(message: msg);
            },
          ),
        ),
        _buildInput(),
      ],
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Pergunta-me sobre anime, manga...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sending ? null : (v) => _send(v),
                  enabled: !_sending,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sending ? null : () => _send(_inputController.text),
                icon: _sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final String createdAt;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                child: Icon(Icons.auto_awesome, size: 16, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16).copyWith(
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                ),
                child: Text(message.content),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(Icons.person, size: 16, color: Theme.of(context).colorScheme.onSecondaryContainer),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: const Radius.circular(4)),
        ),
        child: const SizedBox(
          width: 40,
          height: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Dot(delay: 0),
              _Dot(delay: 150),
              _Dot(delay: 300),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animation = Tween(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

extension on String {
  String sliceSafe(int start, int end) {
    if (length <= start) return '';
    if (length < end) return substring(start);
    return substring(start, end);
  }
}
