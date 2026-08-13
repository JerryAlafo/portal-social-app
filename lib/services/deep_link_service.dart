import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../screens/post/post_detail_screen.dart';

/// Serviço de deep links: links de partilha (`/post/{id}`) abrem a app
/// diretamente no destino. Quem não tem a app cai na versão web.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  /// Navigator global para conseguir navegar a partir do link.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Uri? _pending;
  bool _ready = false;

  Future<void> init() async {
    try {
      final appLinks = AppLinks();

      final initial = await appLinks.getInitialLink();
      if (initial != null) _queue(initial);

      appLinks.uriLinkStream.listen((uri) => _queue(uri));
    } catch (_) {
      // Deep links indisponíveis não devem quebrar o arranque da app.
    }
  }

  /// Marca a app como pronta (navigator montado) e processa links pendentes.
  void notifyReady() {
    _ready = true;
    _tryNavigate();
  }

  void _queue(Uri uri) {
    _pending = uri;
    _tryNavigate();
  }

  void _tryNavigate() {
    final uri = _pending;
    if (uri == null || !_ready) return;
    _pending = null;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    _handle(uri, navigator);
  }

  void _handle(Uri uri, NavigatorState navigator) {
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'post') {
      final postId = segments[1];
      navigator.push(
        MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId)),
      );
    }
  }
}
