import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:portal_social_app/models/profile.dart';
import 'package:portal_social_app/screens/admin/admin_screen.dart';
import 'package:portal_social_app/services/auth_service.dart';
import 'package:portal_social_app/state/theme_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('render admin screen as mod', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: FakeAuthService()),
          ChangeNotifierProvider(create: (_) => ThemeState()),
        ],
        child: MaterialApp(
          home: const AdminScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Administração'), findsOneWidget);
    expect(find.text('Painel'), findsOneWidget);

    await tester.tap(find.text('Utilizadores'));
    await tester.pumpAndSettle();
    expect(find.text('Pesquisar utilizador...'), findsOneWidget);
  });
}

class FakeAuthService extends AuthService {
  @override
  Profile? get profile => const Profile(
        id: '1',
        username: 'mod',
        displayName: 'Mod',
        avatarInitials: 'M',
        role: 'mod',
      );
}
