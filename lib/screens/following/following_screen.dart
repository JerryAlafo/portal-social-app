import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../services/follow_service.dart';
import '../../widgets/avatar.dart';
import '../../widgets/states.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  List<Profile> _users = [];
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
    final res = await FollowService.instance.getFollowing();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        _users = res.data ?? [];
      } else {
        _error = res.error;
      }
    });
  }

  Future<void> _unfollow(Profile user) async {
    final res = await FollowService.instance.toggleFollow(user.id);
    if (!mounted || !res.ok) return;
    setState(() => _users.removeWhere((u) => u.id == user.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('A seguir')),
      body: _loading
          ? const LoadingView(message: 'A carregar...')
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _users.isEmpty
                  ? const EmptyView(
                      message: 'Ainda não segues ninguém.',
                      icon: Icons.person_add_alt_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _users.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final user = _users[i];
                          return ListTile(
                            leading: AppAvatar(
                              url: user.avatarUrl,
                              initials: user.avatarInitials,
                              size: 42,
                              showOnline: true,
                              online: user.isOnline,
                            ),
                            title: Text(
                              user.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                            ),
                            subtitle: Text('@${user.username}'),
                            trailing: OutlinedButton(
                              onPressed: () => _unfollow(user),
                              child: const Text('Deixar de seguir'),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
