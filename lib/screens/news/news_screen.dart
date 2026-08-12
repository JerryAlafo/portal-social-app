import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/news_item.dart';
import '../../services/news_service.dart';
import '../../utils/format.dart';
import '../../widgets/states.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<NewsItem> _news = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await NewsService.instance.getNews();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        _news = res.data ?? [];
      } else {
        _error = res.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notícias')),
      body: _loading
          ? const LoadingView(message: 'A carregar notícias...')
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _news.isEmpty
                  ? const EmptyView(message: 'Sem notícias disponíveis.', icon: Icons.article_outlined)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _news.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => _NewsCard(item: _news[i]),
                      ),
                    ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem item;
  const _NewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => NewsDetailScreen(item: item)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl != null)
              CachedNetworkImage(
                imageUrl: item.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(
                  height: 150,
                  color: const Color(0x227C5CFC),
                  child: const Icon(Icons.article, color: Color(0xFF7C5CFC), size: 36),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.source != null || item.publishedAt != null)
                    Text(
                      [
                        if (item.source != null) item.source!,
                        if (item.publishedAt != null) AppFormat.relativeTime(item.publishedAt),
                      ].join(' · '),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
