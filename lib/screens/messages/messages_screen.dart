import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/conversation.dart';
import '../../services/auth_service.dart';
import '../../services/message_service.dart';
import '../../utils/format.dart';
import '../../widgets/avatar.dart';
import '../../widgets/states.dart';
import 'conversation_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Conversation> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await MessageService.instance.getConversations();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        _items = res.data ?? [];
      } else {
        _error = res.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!auth.isAuthenticated) {
      return const Center(child: Text('Inicia sessão para veres as mensagens.'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              const Text(
                'Mensagens',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingView(message: 'A carregar...')
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : _items.isEmpty
                      ? const EmptyView(
                          message: 'Sem conversas ainda.',
                          icon: Icons.chat_bubble_outline,
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 4),
                            itemBuilder: (context, i) => _ConversationTile(c: _items[i]),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation c;
  const _ConversationTile({required this.c});

  @override
  Widget build(BuildContext context) {
    final user = c.otherUser;
    final muted = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ConversationScreen(conversation: c)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            AppAvatar(
              url: user?.avatarUrl,
              initials: user?.avatarInitials ?? '?',
              size: 48,
              showOnline: true,
              online: user?.isOnline ?? false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user?.displayName ?? 'Conversa',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                      if (c.lastMessage != null)
                        Text(
                          AppFormat.relativeTime(c.lastMessage!.createdAt),
                          style: TextStyle(fontSize: 11.5, color: muted),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.lastMessage?.content ?? 'Sem mensagens ainda',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: c.unreadCount > 0
                                ? Theme.of(context).textTheme.bodyMedium?.color
                                : muted,
                            fontWeight: c.unreadCount > 0 ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (c.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF7C5CFC),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Text(
                            '${c.unreadCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
