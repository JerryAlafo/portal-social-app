import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/conversation.dart';
import '../../services/auth_service.dart';
import '../../services/message_service.dart';
import '../../utils/format.dart';
import '../../widgets/avatar.dart';
import '../../widgets/states.dart';

class ConversationScreen extends StatefulWidget {
  final Conversation conversation;
  const ConversationScreen({super.key, required this.conversation});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final List<Message> _messages = [];
  final _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await MessageService.instance.getMessages(widget.conversation.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) _messages.addAll(res.data ?? []);
    });
    _scrollDown();
    await MessageService.instance.markConversationRead(widget.conversation.id);
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final res = await MessageService.instance.sendMessage(widget.conversation.id, text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (res.ok) {
      _controller.clear();
      setState(() => _messages.add(res.data!));
      _scrollDown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = widget.conversation.otherUser;
    final myId = auth.profile?.id;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AppAvatar(
              url: user?.avatarUrl,
              initials: user?.avatarInitials ?? '?',
              size: 34,
              showOnline: true,
              online: user?.isOnline ?? false,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.displayName ?? 'Conversa', style: const TextStyle(fontSize: 16)),
                Text(
                  (user?.isOnline ?? false) ? 'online' : 'offline',
                  style: TextStyle(fontSize: 12, color: Colors.green.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const LoadingView()
                : _messages.isEmpty
                    ? const EmptyView(message: 'Sem mensagens. Envia algo!', icon: Icons.chat_outlined)
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final mine = m.senderId == myId;
                          return _Bubble(message: m, mine: mine);
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(hintText: 'Escreve uma mensagem...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Message message;
  final bool mine;
  const _Bubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: mine
              ? const Color(0xFF7C5CFC)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.4,
                color: mine ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              AppFormat.relativeTime(message.createdAt),
              style: TextStyle(
                fontSize: 10.5,
                color: mine ? Colors.white.withValues(alpha: 0.7) : muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
