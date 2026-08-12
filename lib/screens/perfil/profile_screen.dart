import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/profile.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/states.dart';
import 'edit_profile_screen.dart';
import 'profile_view.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? _profile;
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
    final res = await ProfileService.instance.getMyProfile();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        _profile = res.data;
      } else {
        _error = res.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (!auth.isAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Inicia sessão para veres o teu perfil.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const LoadingView(message: 'A carregar perfil...')
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _profile == null
                  ? const ErrorView(message: 'Perfil não encontrado.')
                  : ProfileView(
                      profile: _profile!,
                      username: _profile!.username,
                      isOwn: true,
                      onEdit: () async {
                        final updated = await Navigator.of(context).push<Profile>(
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(profile: _profile!),
                          ),
                        );
                        if (updated != null) setState(() => _profile = updated);
                      },
                    ),
    );
  }
}
