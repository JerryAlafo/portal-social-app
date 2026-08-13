import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/auth_service.dart';
import 'services/deep_link_service.dart';
import 'services/update_service.dart';
import 'state/theme_state.dart';
import 'widgets/brand_logo.dart';
import 'widgets/update_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await DeepLinkService.instance.init();
  runApp(const PortalApp());
}

class PortalApp extends StatefulWidget {
  const PortalApp({super.key});

  @override
  State<PortalApp> createState() => _PortalAppState();
}

class _PortalAppState extends State<PortalApp> {
  final AuthService _auth = AuthService();
  final UpdateService _update = UpdateService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.instance.notifyReady();
      if (mounted) _auth.restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _update),
        ChangeNotifierProvider(create: (_) => ThemeState()),
      ],
      child: Consumer<ThemeState>(
        builder: (context, themeState, _) {
          return MaterialApp(
            title: 'Portal Social',
            navigatorKey: DeepLinkService.instance.navigatorKey,
            debugShowCheckedModeBanner: false,
            themeMode: themeState.themeMode,
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            home: _HomeGate(),
          );
        },
      ),
    );
  }
}

class _HomeGate extends StatelessWidget {
  const _HomeGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final updateService = context.watch<UpdateService>();

    if (updateService.latest == null && !updateService.isChecking) {
      Future.microtask(() => updateService.checkForUpdate());
    }

    final currentVersion = const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

    return Column(
      children: [
        UpdateBanner(
          currentVersion: currentVersion,
          onUpdate: () {
            if (updateService.isUpdateRequired(currentVersion)) {
              Future.microtask(() => updateService.downloadAndInstall());
            }
          },
        ),
        Expanded(
          child: _buildAuthGate(context, auth),
        ),
      ],
    );
  }

  Widget _buildAuthGate(BuildContext context, AuthService auth) {
    if (auth.isBooting) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandLogo(size: 56),
              const SizedBox(height: 16),
              const Text(
                'PORTAL',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    if (auth.status == AuthStatus.unknown) {
      return const LoginScreen();
    }

    return const MainShell();
  }
}
