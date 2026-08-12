import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/fanfic.dart';
import '../../utils/format.dart';

class FanficReaderScreen extends StatelessWidget {
  final Fanfic fanfic;
  const FanficReaderScreen({super.key, required this.fanfic});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5);
    final statusLabel = switch (fanfic.status) {
      'complete' => 'Completo',
      'hiatus' => 'Pausado',
      _ => 'Em curso',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(fanfic.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: fanfic.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: fanfic.coverUrl!,
                        width: 88,
                        height: 120,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => _coverPlaceholder(),
                      )
                    : _coverPlaceholder(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fanfic.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    if (fanfic.author != null)
                      Text(
                        'por @${fanfic.author!.username}',
                        style: TextStyle(color: AppColors.accentSoft, fontSize: 13.5),
                      ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        if (fanfic.genre != null) _chip(fanfic.genre!),
                        if (fanfic.fandom != null) _chip(fanfic.fandom!),
                        _chip(statusLabel),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${fanfic.chapters} capítulos · ${fanfic.words} palavras',
                      style: TextStyle(fontSize: 12.5, color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          Text(
            'Sinopse',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: muted,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            fanfic.synopsis ?? 'Sem sinopse.',
            style: const TextStyle(fontSize: 15.5, height: 1.65),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat(context, '${fanfic.readsCount}', 'Leituras'),
              _stat(context, '${fanfic.likesCount}', 'Gostos'),
              _stat(context, AppFormat.date(fanfic.updatedAt), 'Atualizado'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      width: 88,
      height: 120,
      color: AppColors.accent.withValues(alpha: 0.15),
      child: const Icon(Icons.menu_book, color: AppColors.accent, size: 32),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.accentSoft,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    final muted = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5);
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: muted)),
      ],
    );
  }
}
