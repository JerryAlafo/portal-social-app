import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/brand_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _username = TextEditingController();
  final _displayName = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _username.dispose();
    _displayName.dispose();
    super.dispose();
  }

  bool get _isRegister => _tabController.index == 1;

  Future<void> _submit() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = '';
    });

    final auth = context.read<AuthService>();

    if (_isRegister) {
      if (_password.text != _confirmPassword.text) {
        setState(() {
          _error = 'As passwords não coincidem.';
          _loading = false;
        });
        return;
      }
      final res = await auth.register(
        email: _email.text.trim(),
        password: _password.text,
        username: _username.text.trim(),
        displayName: _displayName.text.trim(),
      );
      if (!mounted) return;
      if (!res.ok) {
        setState(() {
          _error = res.error ?? 'Erro ao criar conta.';
          _loading = false;
        });
        return;
      }
      // Sucesso: se o login automático funcionou, navegou automaticamente.
      setState(() => _loading = false);
      if (!auth.isAuthenticated) {
        _showRegisterSuccess();
      }
      return;
    }

    final res = await auth.login(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = res.error ?? '';
    });
  }

  Future<void> _handleGuest() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    await context.read<AuthService>().enableGuestMode();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _handleGoogle() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    final res = await context.read<AuthService>().loginWithGoogle();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!res.ok) _error = res.error ?? 'Erro no login com Google.';
    });
  }

  void _showRegisterSuccess() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conta criada com sucesso!'),
        content: const Text(
          'Podes agora iniciar sessão com as tuas credenciais.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _tabController.animateTo(0);
            },
            child: const Text('Ir para Entrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A página de login replica o web de referência, que é sempre escura.
    const muted = AppColors.darkText2;
    const inputFill = Color(0x0DFFFFFF); // --border2 (#ffffff0d)
    const inputBorder = Color(0x1AFFFFFF); // login-input border (#ffffff1a)
    const inputText = Color(0xFFE0E0E8); // login-input color

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
                    const SizedBox(height: 6),
                    Text(
                      _isRegister
                          ? 'Junta-te a maior comunidade de anime.'
                          : 'O outro mundo espera por ti.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: muted, fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: inputFill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: inputBorder),
                      ),
                      child: SizedBox(
                        height: 46,
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x667C5CFC),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          indicatorColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: const Color(0xFF6B6B7B),
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Entrar'),
                            Tab(text: 'Registar'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isRegister) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              controller: _username,
                              label: 'Nome de utilizador',
                              hint: 'otakufan99',
                              icon: Icons.alternate_email,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              controller: _displayName,
                              label: 'Nome de display',
                              hint: 'Otaku Fan',
                              icon: Icons.person_outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    _field(
                      controller: _email,
                      label: 'Email',
                      hint: 'eu@portal.pt',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _passwordField(
                      controller: _password,
                      label: 'Password',
                      obscure: _obscurePassword,
                      onToggle: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    if (_isRegister) ...[
                      const SizedBox(height: 16),
                      _passwordField(
                        controller: _confirmPassword,
                        label: 'Confirmar password',
                        obscure: _obscurePassword,
                        onToggle: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ],
                    if (!_isRegister) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Esqueceu a password?',
                            style: TextStyle(color: AppColors.accent),
                          ),
                        ),
                      ),
                    ],
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
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _loading ? null : _handleGoogle,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: inputBorder),
                        foregroundColor: inputText,
                        backgroundColor: inputFill,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Image(
                        image: AssetImage('assets/images/google_g.png'),
                        width: 20,
                        height: 20,
                      ),
                      label: Text(
                        _isRegister
                            ? 'Registar com Google'
                            : 'Entrar com Google',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _Divider(),
                    const SizedBox(height: 16),
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
                          : Text(
                              _isRegister ? 'Criar conta' : 'Entrar no PORTAL',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                    if (!_isRegister) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loading ? null : _handleGuest,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0x1A7C5CFC),
                          foregroundColor: const Color(0xFFD8D0FF),
                          side: const BorderSide(color: Color(0x6B9B7FFF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Continuar como convidado',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (_isRegister)
                      const Text(
                        'Ao registar-te aceitas os termos da comunidade.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted, fontSize: 12),
                      )
                    else
                      TextButton(
                        onPressed: () => _tabController.animateTo(1),
                        child: Text(
                          'Ainda não tens conta? Regista-te',
                          style: TextStyle(
                            color: AppColors.accentSoft,
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
    TextInputType? keyboardType,
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
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFFE0E0E8)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF5A5A6B)),
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

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
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
          obscureText: obscure,
          style: const TextStyle(color: Color(0xFFE0E0E8)),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: Color(0xFF5A5A6B)),
            prefixIcon: const Icon(
              Icons.lock_outline,
              size: 20,
              color: Color(0xFF8B8B9B),
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: const Color(0xFF5A5A6B),
              ),
            ),
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

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0x1AFFFFFF))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('ou', style: TextStyle(color: Color(0x4DFFFFFF))),
        ),
        Expanded(child: Divider(color: Color(0x1AFFFFFF))),
      ],
    );
  }
}
