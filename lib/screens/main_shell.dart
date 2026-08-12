import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../services/auth_service.dart';
import '../services/count_service.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/events/events_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../screens/fanfics/fanfics_screen.dart';
import '../screens/feed/feed_screen.dart';
import '../screens/following/following_screen.dart';
import '../screens/gallery/gallery_screen.dart';
import '../screens/messages/messages_screen.dart';
import '../screens/news/news_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/ia_portal/ia_portal_screen.dart';
import '../screens/perfil/profile_screen.dart';
import '../screens/post/create_post_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../state/theme_state.dart';
import '../utils/access.dart';
import '../widgets/avatar.dart';
import '../widgets/brand_logo.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  Timer? _countsTimer;
  int _unreadNotifs = 0;
  int _unreadMsgs = 0;

  final _screens = const [
    FeedScreen(),
    ExploreScreen(),
    NotificationsScreen(),
    MessagesScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _countsTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _loadCounts(),
    );
  }

  @override
  void dispose() {
    _countsTimer?.cancel();
    super.dispose();
  }

  /// Usa o endpoint /api/counts da rede social web (como no sidebar da web).
  Future<void> _loadCounts() async {
    final auth = context.read<AuthService>();
    if (!auth.isAuthenticated) return;
    final res = await CountService.instance.getCounts();
    if (!mounted) return;
    if (res.ok && res.data != null) {
      setState(() {
        _unreadNotifs = res.data!.unreadNotifications;
        _unreadMsgs = res.data!.unreadMessages;
      });
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _badge(int count, Widget child) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: child,
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Feed';
      case 1:
        return 'Explorar';
      case 2:
        return 'Alertas';
      case 3:
        return 'Chat';
      case 4:
        return 'Definições';
      default:
        return 'PORTAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final themeState = context.watch<ThemeState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForIndex(_index)),
        actions: [
          if (auth.isAuthenticated && auth.profile != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _navigateTo(const ProfileScreen()),
                child: AppAvatar(
                  url: auth.profile!.avatarUrl,
                  initials: auth.profile!.avatarInitials,
                  size: 30,
                ),
              ),
            ),
        ],
      ),
      drawer: _buildDrawer(context, auth, themeState),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!requireLogin(context)) return;
          _navigateTo(const CreatePostScreen());
        },
        child: const Icon(Icons.edit),
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i >= 2 && !auth.isAuthenticated && !auth.isGuest) {
            if (!requireLogin(context)) return;
          }
          setState(() => _index = i);
          if (i == 2 || i == 3) _loadCounts();
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Feed'),
          const NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explorar'),
          NavigationDestination(
            icon: _badge(_unreadNotifs, const Icon(Icons.notifications_outlined)),
            selectedIcon: _badge(_unreadNotifs, const Icon(Icons.notifications)),
            label: 'Alertas',
          ),
          NavigationDestination(
            icon: _badge(_unreadMsgs, const Icon(Icons.chat_bubble_outline)),
            selectedIcon: _badge(_unreadMsgs, const Icon(Icons.chat_bubble)),
            label: 'Chat',
          ),
          const NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Definições'),
        ],
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    AuthService auth,
    ThemeState themeState,
  ) {
    final isDark = themeState.darkMode;
    final muted = (isDark ? AppColors.darkText : AppColors.lightText)
        .withValues(alpha: 0.6);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  const BrandLogo(size: 32),
                  const SizedBox(width: 10),
                  const Text(
                    'PORTAL',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const Spacer(),
                  if (auth.isAuthenticated && auth.profile != null)
                    AppAvatar(
                      url: auth.profile!.avatarUrl,
                      initials: auth.profile!.avatarInitials,
                      size: 32,
                    ),
                ],
              ),
            ),
            if (auth.isAuthenticated && auth.profile != null) ...[
              ListTile(
                leading: AppAvatar(
                  url: auth.profile!.avatarUrl,
                  initials: auth.profile!.avatarInitials,
                ),
                title: Text(
                  auth.profile!.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('@${auth.profile!.username}'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateTo(const ProfileScreen());
                },
              ),
              const Divider(),
            ] else if (auth.isGuest) ...[
              const ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('Convidado'),
                subtitle: Text('A navegar como convidado'),
              ),
              ListTile(
                leading: const Icon(Icons.login),
                title: Text('Iniciar sessão', style: TextStyle(color: AppColors.accentSoft)),
                onTap: () {
                  Navigator.pop(context);
                  auth.exitGuestMode();
                },
              ),
              const Divider(),
            ],
            _drawerItem(context, Icons.search, 'Pesquisar', () {
              Navigator.pop(context);
              _navigateTo(const SearchScreen());
            }),
            _drawerItem(context, Icons.newspaper_outlined, 'Notícias', () {
              Navigator.pop(context);
              _navigateTo(const NewsScreen());
            }),
            _drawerItem(context, Icons.event_outlined, 'Eventos', () {
              Navigator.pop(context);
              _navigateTo(const EventsScreen());
            }),
            _drawerItem(context, Icons.menu_book_outlined, 'Fanfics', () {
              Navigator.pop(context);
              _navigateTo(const FanficsScreen());
            }),
            _drawerItem(context, Icons.photo_library_outlined, 'Galeria', () {
              Navigator.pop(context);
              _navigateTo(const GalleryScreen());
            }),
            _drawerItem(context, Icons.auto_awesome, 'IA Portal', () {
              Navigator.pop(context);
              _navigateTo(const IaPortalScreen());
            }),
            _drawerItem(context, Icons.people_outline, 'Seguindo', () {
              Navigator.pop(context);
              if (!requireLogin(context)) return;
              _navigateTo(const FollowingScreen());
            }),
            _drawerItem(context, Icons.person_outline, 'Perfil', () {
              Navigator.pop(context);
              if (!requireLogin(context)) return;
              _navigateTo(const ProfileScreen());
            }),
            if (auth.isAuthenticated && (auth.profile?.isMod ?? false)) ...[
              const Divider(),
              _drawerItem(context, Icons.admin_panel_settings_outlined, 'Admin', () {
                Navigator.pop(context);
                _navigateTo(const AdminScreen());
              }, color: AppColors.pink),
            ],
            const Divider(),
            const Divider(),
            ListTile(
              leading: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: muted,
              ),
              title: Text(isDark ? 'Modo claro' : 'Modo escuro'),
              trailing: Switch(
                value: isDark,
                onChanged: (_) => themeState.toggle(),
              ),
              onTap: themeState.toggle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: color != null ? TextStyle(color: color) : null),
      onTap: onTap,
    );
  }
}
