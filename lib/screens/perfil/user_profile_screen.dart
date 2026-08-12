import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../services/user_service.dart';
import '../../widgets/states.dart';
import 'profile_view.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;
  final Profile? initialProfile;

  const UserProfileScreen({super.key, required this.username, this.initialProfile});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Profile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await UserService.instance.getByUsername(widget.username);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok && res.data != null) {
        _profile = res.data!.profile;
      } else if (_profile == null) {
        _error = res.error ?? 'Utilizador não encontrado.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: _loading && _profile == null
          ? const LoadingView(message: 'A carregar perfil...')
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _profile == null
                  ? const ErrorView(message: 'Utilizador não encontrado.')
                  : ProfileView(
                      profile: _profile!,
                      username: widget.username,
                      isOwn: false,
                    ),
    );
  }
}
