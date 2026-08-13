import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../services/update_service.dart';

class UpdateBanner extends StatelessWidget {
  final String currentVersion;
  final VoidCallback? onUpdate;
  final VoidCallback? onDismiss;

  const UpdateBanner({
    super.key,
    required this.currentVersion,
    this.onUpdate,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: UpdateService(),
      child: Consumer<UpdateService>(
        builder: (context, updateService, _) {
          final info = updateService.latest;
          if (info == null) {
            return const SizedBox.shrink();
          }

          // A atualização obrigatória é apresentada no ForcedUpdateScreen,
          // que bloqueia a app — aqui fica só a atualização opcional.
          if (updateService.isUpdateRequired(currentVersion)) {
            return const SizedBox.shrink();
          }
          if (!updateService.isUpdateAvailable(currentVersion)) {
            return const SizedBox.shrink();
          }
          if (updateService.isDismissed(info.version)) {
            return const SizedBox.shrink();
          }

          final color = AppColors.accent;
          final icon = Icons.system_update_rounded;
          const title = 'Atualização disponível';
          final message = 'Há uma nova versão disponível (${info.version}).';

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    if (onDismiss != null)
                      Material(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            updateService.markDismissed(info.version);
                            onDismiss?.call();
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                if (info.releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      info.releaseNotes,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await updateService.downloadAndInstall();
                      onUpdate?.call();
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Baixar atualização'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
