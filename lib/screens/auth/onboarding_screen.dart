import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/brand_logo.dart';

/// Passo de onboarding para contas criadas via Google (username em falta),
/// replicando app/onboarding do projeto de referência.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static final _usernameRegExp = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _displayName = TextEditingController();

  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _displayName.text = context.read<AuthService>().profile?.displayName ?? '';
  }

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = '';
    });

    final updates = <String, dynamic>{'username': _username.text.trim()};
    final display = _displayName.text.trim();
    if (display.isNotEmpty) updates['display_name'] = display;

    final auth = context.read<AuthService>();
    final res = await ProfileService.instance.updateProfile(updates);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.ok && res.data != null) {
      auth.applyProfile(res.data!);
    } else {
      setState(() => _error = res.error ?? 'Erro ao guardar o perfil.');
    }
  }

  Future<void> _logout() async {
    if (_loading) return;
    await context.read<AuthService>().logout();
  }

  @override
  Widget build(BuildContext context) {
    // A página replica o onboarding da web, que usa o mesmo estilo do login.
    const muted = AppColors.darkText2;

    return Scaffold(
      backgroundColor: AppColors.loginBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandLogo(size: 56)),
                    const SizedBox(height: 12),
                    const Text(
                      'PORTAL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        color: AppColors.accentSoft,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Completa o teu perfil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Escolhe um nome de utilizador único para dares a conhecer na comunidade.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: muted, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    _field(
                      controller: _username,
                      label: 'Nome de utilizador',
                      hint: 'otakufan99',
                      icon: Icons.alternate_email,
                      maxLength: 20,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9_]'),
                        ),
                      ],
                      validator: (value) {
                        final v = (value ?? '').trim();
                        if (v.isEmpty) return 'Escolhe um nome de utilizador.';
                        if (!_usernameRegExp.hasMatch(v)) {
                          return '3-20 caracteres, letras, números e _.';
                        }
                        return null;
                      },
                      helperText: '3-20 caracteres, letras, números e _',
                    ),
                    const SizedBox(height: 16),
                    _field(
                      controller: _displayName,
                      label: 'Nome de display',
                      hint: 'Otaku Fan',
                      icon: Icons.person_outline,
                      maxLength: 30,
                      helperText: 'O nome que aparece no teu perfil',
                    ),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _error,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Continuar',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading ? null : _logout,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Sair da conta',
                        style: TextStyle(
                          color: AppColors.darkText3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int? maxLength,
    String? helperText,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8B8B9B),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(color: Color(0xFFE0E0E8)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF5A5A6B)),
            helperText: helperText,
            helperStyle: const TextStyle(color: Color(0xFF6B6B7B), fontSize: 11),
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF8B8B9B)),
            filled: true,
            fillColor: const Color(0x0DFFFFFF),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0x1AFFFFFF)),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0x1AFFFFFF)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
