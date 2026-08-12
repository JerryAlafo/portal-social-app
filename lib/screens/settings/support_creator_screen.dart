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
            iconUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/WhatsApp/1200px-WhatsApp.png',
            label: 'WhatsApp',
            sublabel: _whatsapp,
            color: const Color(0xFF25D366),
            onTap: () => _open('https://wa.me/258833066530'),
          ),
          _SocialTile(
            iconUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/LinkedIn_logo_initials.png/1200px-LinkedIn_logo_initials.png',
            label: 'LinkedIn',
            sublabel: 'Jerry de Jesus',
            color: const Color(0xFF0A66C2),
            onTap: () => _open(_linkedin),
          ),
          _SocialTile(
            iconUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Instagram_logo_2016.svg/1200px-Instagram_logo_2016.svg.png',
            label: 'Instagram',
            sublabel: '@jerry_org_',
            color: const Color(0xFFE4405F),
            onTap: () => _open(_instagram),
          ),
          _SocialTile(
            iconUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Instagram_logo_2016.svg/1200px-Instagram_logo_2016.svg.png',
            label: 'Instagram Jobs',
            sublabel: '@jerry_org_jobs',
            color: const Color(0xFFF77737),
            onTap: () => _open(_instagramJobs),
          ),
          _SocialTile(
            iconUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/42/YouTube_icon_%282013-2017%29.png/1200px-YouTube_icon_%282013-2017%29.png',
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
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link.')),
      );
    }
  }
}

class _SocialTile extends StatelessWidget {
  final String iconUrl;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _SocialTile({
    required this.iconUrl,
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
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.network(
                    iconUrl,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.public, color: color, size: 22);
                    },
                  ),
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
