import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportCreatorScreen extends StatelessWidget {
  const SupportCreatorScreen({super.key});

  static const _whatsapp = '+258833066530';
  static const _linkedin = 'https://www.linkedin.com/in/jerry-de-jesus-gomes-alafo-53677b294/';
  static const _instagram = 'https://www.instagram.com/jerry_org_/?utm_source=ig_web_button_share_sheet&igsh=ZDNlZDc0MzIxNw==';
  static const _instagramJobs = 'https://www.instagram.com/jerry_org_jobs/?hl=fa';
  static const _youtube = 'https://www.youtube.com/channel/UCKmIif3KVJKlHK7NcjhXWlg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suporte / Criador'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    'JA',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jerry de Jesus Gomes Alafo',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Criador do Portal Social',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SocialTile(
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            sublabel: _whatsapp,
            color: const Color(0xFF25D366),
            onTap: () => _open(_whatsapp.replaceFirst('+', '')),
          ),
          _SocialTile(
            icon: Icons.work_rounded,
            label: 'LinkedIn',
            sublabel: 'Jerry de Jesus',
            color: const Color(0xFF0A66C2),
            onTap: () => _open(_linkedin),
          ),
          _SocialTile(
            icon: Icons.camera_alt_rounded,
            label: 'Instagram',
            sublabel: '@jerry_org_',
            color: const Color(0xFFE4405F),
            onTap: () => _open(_instagram),
          ),
          _SocialTile(
            icon: Icons.business_center_rounded,
            label: 'Instagram Jobs',
            sublabel: '@jerry_org_jobs',
            color: const Color(0xFFF77737),
            onTap: () => _open(_instagramJobs),
          ),
          _SocialTile(
            icon: Icons.play_circle_filled_rounded,
            label: 'YouTube',
            sublabel: 'Portal Social',
            color: const Color(0xFFFF0000),
            onTap: () => _open(_youtube),
          ),
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SocialTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _SocialTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        sublabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
