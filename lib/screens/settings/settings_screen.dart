import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../state/theme_state.dart';
import '../../widgets/states.dart';
import '../perfil/edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Terminar sessão'),
        content: const Text('Tens a certeza que queres terminar a sessão?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Terminar')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AuthService>().logout();
  }

  Future<void> _deleteAccount() async {
    final auth = context.read<AuthService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar conta'),
        content: const Text(
          'Tens a certeza? Esta ação apaga permanentemente a tua conta e todo o conteúdo. Não pode ser anulada.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFC5C7D)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final res = await auth.deleteAccount();
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok) {
      await auth.logout();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Erro ao eliminar conta')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final auth = context.watch<AuthService>();
    final isGuest = auth.isGuest;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              const Text(
                'Definições',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        Expanded(
          child: _busy
              ? const LoadingView(message: 'A processar...')
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    const _SectionLabel('Aparência'),
                    SwitchListTile(
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Tema escuro'),
                      value: theme.darkMode,
                      onChanged: (v) => theme.setDark(v),
                    ),
                    const Divider(),
                    const _SectionLabel('Conta'),
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Editar perfil'),
                      onTap: isGuest || auth.profile == null
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EditProfileScreen(profile: auth.profile!),
                                ),
                              ),
                    ),
                    if (!isGuest) ...[
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Terminar sessão'),
                        onTap: _logout,
                      ),
                      ListTile(
                        leading: Icon(Icons.delete_forever_outlined,
                            color: Theme.of(context).colorScheme.error),
                        title: Text('Eliminar conta',
                            style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        onTap: _deleteAccount,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Portal Social App v0.1.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
