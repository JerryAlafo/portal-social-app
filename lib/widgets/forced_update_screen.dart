import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../services/update_service.dart';
import 'brand_logo.dart';

/// Ecrã de atualização obrigatória: substitui toda a app até a nova versão
/// ser instalada. Não pode ser fechado (nem com o botão voltar do sistema).
class ForcedUpdateScreen extends StatelessWidget {
  const ForcedUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.loginBg,
        body: Consumer<UpdateService>(
          builder: (context, updateService, _) {
            final info = updateService.latest;
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.system_update_alt_rounded,
                              color: AppColors.danger,
                              size: 38,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Atualização obrigatória',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          info == null
                              ? 'É necessária uma nova versão do PORTAL.'
                              : 'A versão ${info.version} já está disponível e esta '
                                  'versão já não é suportada.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.darkText2,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0x0DFFFFFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x1AFFFFFF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Novidades',
                                style: TextStyle(
                                  color: Color(0xFF8B8B9B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (info?.releaseNotes.isNotEmpty ?? false)
                                    ? info!.releaseNotes
                                    : 'Atualiza para continuar a usar o app.',
                                style: const TextStyle(
                                  color: Color(0xFFE0E0E8),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => updateService.downloadAndInstall(),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.download_rounded, size: 20),
                          label: const Text(
                            'Atualizar agora',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'O app fica bloqueado até instalares a nova versão.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.darkText3,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
