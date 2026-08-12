import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/news_item.dart';
import '../../utils/format.dart';
import '../../widgets/states.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsItem item;
  const NewsDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    return Scaffold(
      appBar: AppBar(title: const Text('Notícia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (item.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(
                  height: 180,
                  color: const Color(0x227C5CFC),
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (item.category != null) ...[
            Text(item.category!.toUpperCase(), style: TextStyle(fontSize: 12, color: muted, letterSpacing: 1.5)),
            const SizedBox(height: 6),
          ],
          Text(
            item.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.3),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (item.source != null)
                Text(
                  item.source!,
                  style: TextStyle(fontSize: 13, color: muted),
                ),
              const Spacer(),
              Text(
                AppFormat.relativeTime(item.publishedAt),
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
          const Divider(height: 28),
          if (item.summary != null && item.summary!.isNotEmpty)
            SelectableText(
              item.summary!,
              style: const TextStyle(fontSize: 15.5, height: 1.65),
            )
          else
            const EmptyView(message: 'Sem conteúdo.', icon: Icons.article_outlined),
        ],
      ),
    );
  }
}
