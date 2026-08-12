import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/event.dart';
import '../../models/post.dart';
import '../../services/event_service.dart';
import '../../services/post_service.dart';
import '../../services/suggestion_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/states.dart';
import '../post/post_detail_screen.dart';

const _exploreFilters = [
  {'id': 'trending', 'label': 'Em Alta', 'icon': Icons.trending_up},
  {'id': 'hot', 'label': 'Popular', 'icon': Icons.local_fire_department},
  {'id': 'recent', 'label': 'Recente', 'icon': Icons.schedule},
  {'id': 'top', 'label': 'Top', 'icon': Icons.star},
];

const _exploreCategories = ['Tudo', 'Shonen', 'Shojo', 'Isekai', 'Seinen', 'Cosplay', 'Manga', 'Figura', 'AMV', 'Fanfic', 'Arte'];

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Event> _events = [];
  List<Post> _posts = [];
  bool _loading = true;
  bool _loadingPosts = false;
  String? _error;
  String _filter = 'trending';
  String _category = 'Tudo';
  int _page = 0;
  bool _hasMore = true;

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
    final results = await Future.wait([
      SuggestionService.instance.getTrending(),
      SuggestionService.instance.getSuggestions(),
      EventService.instance.getEvents(),
    ]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      final t = results[0];
      final e = results[2];
      if (t.ok && t.data != null) {}
      if (e.ok && e.data != null) _events = List<Event>.from(e.data!);
      if (!t.ok) {
        _error = t.error ?? 'Erro ao carregar.';
      }
    });
    await _loadPosts(refresh: true);
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    if (_loadingPosts || (!_hasMore && !refresh)) return;
    setState(() => _loadingPosts = true);
    final targetPage = refresh ? 1 : _page + 1;
    final category = _category == 'Tudo' ? null : _category;
    final res = await PostService.instance.getFeed(targetPage, 20, category: category, filter: _filter);
    if (!mounted) return;
    setState(() {
      _loadingPosts = false;
      if (res.ok && res.data != null) {
        _hasMore = res.data!.length == 20;
        _page = targetPage;
        if (refresh) {
          _posts
            ..clear()
            ..addAll(res.data!);
        } else {
          _posts.addAll(res.data!);
        }
      }
    });
  }

  void _showPostMenu(BuildContext context, Post post) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const LoadingView(message: 'A carregar...')
        : _error != null
            ? ErrorView(message: _error!, onRetry: _load)
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemCount: _exploreFilters.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final f = _exploreFilters[i];
                          final active = _filter == f['id'];
                          return FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(f['icon'] as IconData, size: 16),
                                const SizedBox(width: 6),
                                Text(f['label'] as String),
                              ],
                            ),
                            selected: active,
                            onSelected: (v) {
                              if (!v) return;
                              setState(() {
                                _filter = f['id'] as String;
                                _posts.clear();
                                _page = 0;
                                _hasMore = true;
                              });
                              _loadPosts(refresh: true);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemCount: _exploreCategories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (context, i) {
                          final c = _exploreCategories[i];
                          final active = _category == c;
                          return ChoiceChip(
                            label: Text(c),
                            selected: active,
                            showCheckmark: false,
                            onSelected: (v) {
                              if (!v) return;
                              setState(() {
                                _category = c;
                                _posts.clear();
                                _page = 0;
                                _hasMore = true;
                              });
                              _loadPosts(refresh: true);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_events.isNotEmpty) ...[
                      Text(
                        'Próximos eventos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._events.take(3).map((e) => Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: Container(
                                width: 48,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${DateTime.parse(e.date).day}',
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      e.title.split(' ').first,
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(e.title,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                              subtitle: Text('${e.location ?? 'Sem local'} · ${e.interestedCount + e.goingCount} interessados'),
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Publicações',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_posts.isEmpty && !_loadingPosts)
                      const EmptyView(message: 'Sem publicações.', icon: Icons.article_outlined)
                    else
                      ..._posts.map((p) => PostCard(
                            post: p,
                            onMore: () => _showPostMenu(context, p),
                          )),
                    if (_loadingPosts)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              );
  }
}
