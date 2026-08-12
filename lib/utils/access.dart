import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

/// Verifica se a sessão permite aceder a uma área restrita.
/// Se for convidado, mostra um diálogo e devolve false.
bool requireLogin(BuildContext context) {
  final auth = context.read<AuthService>();
  if (auth.isAuthenticated) return true;

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Inicia sessão'),
      content: const Text('Precisas de iniciar sessão para aceder a esta funcionalidade.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            // Sai do modo convidado — o router raiz volta ao ecrã de login.
            context.read<AuthService>().exitGuestMode();
          },
          child: const Text('Entrar'),
        ),
      ],
    ),
  );
  return false;
}
