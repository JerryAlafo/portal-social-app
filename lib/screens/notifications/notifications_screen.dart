import 'package:flutter/material.dart' hide Notification;
import 'package:provider/provider.dart';

import '../../models/notification.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../utils/format.dart';
import '../../widgets/avatar.dart';
import '../../widgets/states.dart';
import '../perfil/user_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Notification> _items = [];
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
    final res = await NotificationService.instance.getNotifications();
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
      return const Center(child: Text('Inicia sessão para veres as notificações.'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              const Text(
                'Notificações',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  await NotificationService.instance.markAllAsRead();
                  setState(() {
                    for (final n in _items) {
                      _items[_items.indexOf(n)] = Notification(
                        id: n.id,
                        userId: n.userId,
                        actorId: n.actorId,
                        type: n.type,
                        postId: n.postId,
                        eventId: n.eventId,
                        isRead: true,
                        createdAt: n.createdAt,
                        actor: n.actor,
                      );
                    }
                  });
                },
                child: const Text('Marcar todas'),
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
                          message: 'Sem notificações.',
                          icon: Icons.notifications_none,
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 4),
                            itemBuilder: (context, i) => _NotificationTile(n: _items[i]),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Notification n;
  const _NotificationTile({required this.n});

  String get _message {
    final name = n.actor?.displayName ?? 'Alguém';
    switch (n.type) {
      case 'like':
        return '$name gostou da tua publicação';
      case 'comment':
        return '$name comentou a tua publicação';
      case 'follow':
        return '$name começou a seguir-te';
      case 'share':
        return '$name partilhou a tua publicação';
      case 'mention':
        return '$name mencionou-te';
      case 'repost':
        return '$name repostou a tua publicação';
      default:
        return '$name interagiu contigo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (n.actor != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(
                username: n.actor!.username,
                initialProfile: null,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.transparent : const Color(0xFF7C5CFC).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (n.actor != null)
              AppAvatar(
                url: n.actor!.avatarUrl,
                initials: n.actor!.avatarInitials,
                size: 40,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    AppFormat.relativeTime(n.createdAt),
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ),
            ),
            if (!n.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF7C5CFC),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
