import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/api_response.dart';
import '../../models/announcement.dart';
import '../../models/post.dart';
import '../../models/profile.dart';
import '../../services/post_service.dart';
import '../../services/suggestion_service.dart';
import '../../services/follow_service.dart';
import '../../services/auth_service.dart';
import '../../utils/access.dart';
import '../../widgets/avatar.dart';
import '../../widgets/post_card.dart';
import '../../widgets/states.dart';
import '../perfil/user_profile_screen.dart';
import '../post/post_detail_screen.dart';

const kCategories = [
  'Tudo',
  'Shonen',
  'Shojo',
  'Isekai',
  'Seinen',
  'Cosplay',
  'Manga',
  'Figura',
  'AMV',
  'Outro',
];

const _tabs = ['Geral', 'A seguir', 'Sugestoes', 'Anuncios'];

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scroll = ScrollController();
  final List<Post> _posts = [];
  final List<Profile> _suggestions = [];
  final List<Announcement> _announcements = [];

  String _activeCategory = 'Tudo';
  String _activeTab = 'Geral';
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  bool _initialLoading = true;
  bool _loadingAnnouncements = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(refresh: true);
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      _load();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading || (!_hasMore && !refresh)) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final targetPage = refresh ? 1 : _page + 1;
    String? filter;
    String? category;

    if (_activeTab == 'A seguir') {
      filter = 'following';
    } else if (_activeTab == 'Anuncios') {
      category = 'Anuncios';
    } else {
      category = _activeCategory != 'Tudo' ? _activeCategory : null;
    }

    final res = await PostService.instance.getFeed(
      targetPage,
      20,
      category: category,
      filter: filter,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _initialLoading = false;
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
      } else {
        if (_posts.isEmpty) _error = res.error ?? 'Erro ao carregar feed.';
      }
    });
  }

  Future<void> _loadSuggestions() async {
    final res = await SuggestionService.instance.getSuggestions();
    if (!mounted) return;
    setState(() {
      if (res.ok && res.data != null) {
        _suggestions
          ..clear()
          ..addAll(res.data!);
      }
    });
  }

  Future<void> _loadAnnouncements() async {
    if (_loadingAnnouncements) return;
    setState(() => _loadingAnnouncements = true);
    try {
      final res = await ApiClient.instance.get('/api/announcements');
      if (!mounted) return;
      final result = ApiParser.parse<List<Announcement>>(
        res,
        (json) => (json as List)
            .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      if (result.ok && result.data != null) {
        setState(() {
          _announcements
            ..clear()
            ..addAll(result.data!);
        });
      } else {
        setState(() => _announcements.clear());
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _announcements.clear());
    } finally {
      if (mounted) setState(() => _loadingAnnouncements = false);
    }
  }

  void _onTabChanged(String tab) {
    setState(() => _activeTab = tab);
    _posts.clear();
    _page = 0;
    _hasMore = true;
    _initialLoading = true;
    _error = null;
    if (tab == 'Sugestoes') {
      _loadSuggestions();
    } else {
      _load(refresh: true);
    }
    if (tab == 'Anuncios' || tab == 'Geral') {
      if (_announcements.isEmpty) {
        _loadAnnouncements();
      }
    }
  }

  void _onCategoryChanged(String category) {
    setState(() => _activeCategory = category);
    _posts.clear();
    _page = 0;
    _hasMore = true;
    _initialLoading = true;
    _error = null;
    _load(refresh: true);
  }

  Future<void> _toggleLike(Post post) async {
    if (!requireLogin(context)) return;
    final res = await PostService.instance.toggleLike(post.id);
    if (!mounted || !res.ok) return;
    final liked = res.data ?? false;
    setState(() {
      final i = _posts.indexWhere((p) => p.id == post.id);
      if (i != -1) {
        _posts[i] = _posts[i].copyWith(
          likedByMe: liked,
          likesCount: _posts[i].likesCount + (liked ? 1 : -1),
        );
      }
    });
  }

  void _openPost(Post post) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
    );
  }

  void _openProfile(Post post) {
    final author = post.author ?? post.repost?.author;
    if (author == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          username: author.username,
          initialProfile: Profile(
            id: author.id,
            username: author.username,
            displayName: author.displayName,
            avatarInitials: author.avatarInitials,
            avatarUrl: author.avatarUrl,
            role: author.role ?? 'member',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: Column(
        children: [
          _buildCategoryChips(),
          _buildTabs(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: kCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = kCategories[i];
          final active = c == _activeCategory && _activeTab != 'Anuncios';
          return ChoiceChip(
            label: Text(c),
            selected: active,
            showCheckmark: false,
            onSelected: (_) => _onCategoryChanged(c),
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, i) {
          final t = _tabs[i];
          final active = t == _activeTab;
          return TextButton(
            style: TextButton.styleFrom(
              foregroundColor: active
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            onPressed: () {
              if (t == 'A seguir' && !requireLogin(context)) return;
              _onTabChanged(t);
            },
            child: Text(t),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_activeTab == 'Sugestoes') {
      return _buildSuggestions();
    }
    if (_initialLoading)
      return const LoadingView(message: 'A carregar feed...');
    if (_error != null && _posts.isEmpty) {
      return ErrorView(message: _error!, onRetry: () => _load(refresh: true));
    }

    final showAnnouncements =
        _activeTab == 'Anuncios' ||
        (_activeTab == 'Geral' && _announcements.any((a) => a.pinned));
    final visibleAnnouncements = showAnnouncements
        ? _announcements
              .where((a) => _activeTab == 'Geral' ? a.pinned : true)
              .toList()
        : <Announcement>[];

    if (_posts.isEmpty && visibleAnnouncements.isEmpty) {
      return const EmptyView(
        message: 'Ainda não há publicações aqui.',
        icon: Icons.article_outlined,
      );
    }

    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: _posts.length + visibleAnnouncements.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i < visibleAnnouncements.length) {
          final a = visibleAnnouncements[i];
          return _AnnouncementCard(announcement: a);
        }
        final postIndex = i - visibleAnnouncements.length;
        if (postIndex == _posts.length) {
          if (_loading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox(height: 16);
        }
        final post = _posts[postIndex];
        return PostCard(
          post: post,
          onTap: () => _openPost(post),
          onLike: () => _toggleLike(post),
          onComment: () => _openPost(post),
          onRepost: () => _openPost(post),
          onShare: () => PostService.shareWithSheet(
            postId: post.id,
            content: post.content,
          ),
          onMore: () => _showPostMenu(post),
        );
      },
    );
  }

  Widget _buildSuggestions() {
    return _suggestions.isEmpty
        ? const LoadingView(message: 'A carregar sugestões...')
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _suggestions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final u = _suggestions[i];
              return _SuggestionTile(profile: u);
            },
          );
  }

  void _showPostMenu(Post post) {
    final auth = context.read<AuthService>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final isOwn =
            auth.isAuthenticated &&
            auth.profile != null &&
            auth.profile!.id == post.authorId;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Ver perfil'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openProfile(post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.repeat),
                title: const Text('Repostar'),
                onTap: () {
                  Navigator.pop(ctx);
                  if (!requireLogin(context)) return;
                  _showRepostDialog(post);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.report_outlined,
                  color: Color(0xFFFC5C7D),
                ),
                title: const Text('Denunciar'),
                onTap: () {
                  Navigator.pop(ctx);
                  if (!requireLogin(context)) return;
                  _showReportDialog(post);
                },
              ),
              if (isOwn)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFFC5C7D),
                  ),
                  title: const Text('Apagar publicação'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete(post);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showRepostDialog(Post post) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Repostar'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 280,
          decoration: const InputDecoration(
            hintText: 'Adiciona um comentário (opcional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Repostar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final res = await PostService.instance.repostPost(
        post.id,
        content: controller.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.ok ? 'Publicação repostada!' : (res.error ?? 'Erro.'),
          ),
        ),
      );
    }
  }

  Future<void> _showReportDialog(Post post) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Denunciar publicação'),
        content: TextField(
          controller: reason,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Motivo da denúncia'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Denunciar'),
          ),
        ],
      ),
    );
    if (ok == true && reason.text.trim().isNotEmpty) {
      final res = await PostService.instance.reportPost(
        post.id,
        reason: reason.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.ok ? 'Denúncia enviada. Obrigado!' : (res.error ?? 'Erro.'),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(Post post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar publicação'),
        content: const Text(
          'Tens a certeza que queres apagar esta publicação?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFC5C7D),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final res = await PostService.instance.deletePost(post.id);
      if (!mounted) return;
      if (res.ok) {
        setState(() => _posts.removeWhere((p) => p.id == post.id));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res.error ?? 'Erro ao apagar.')));
      }
    }
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF7C5CFC).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF7C5CFC).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C5CFC).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Anúncio',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7C5CFC),
                  ),
                ),
              ),
              if (announcement.pinned) ...[
                const SizedBox(width: 8),
                const Icon(Icons.push_pin, size: 14, color: Color(0xFFFCB45C)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            announcement.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          if (announcement.content != null &&
              announcement.content!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              announcement.content!,
              style: TextStyle(
                fontSize: 13.5,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.75,
                ),
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (announcement.authorUsername != null)
                Text(
                  '@${announcement.authorUsername}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
              if (announcement.authorUsername != null) const SizedBox(width: 8),
              Text(
                announcement.createdAt != null
                    ? _formatDate(announcement.createdAt!)
                    : '',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.tryParse(dateStr);
      if (date == null) return '';
      final months = [
        'Jan',
        'Fev',
        'Mar',
        'Abr',
        'Mai',
        'Jun',
        'Jul',
        'Ago',
        'Set',
        'Out',
        'Nov',
        'Dez',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return '';
    }
  }
}

class _SuggestionTile extends StatelessWidget {
  final Profile profile;
  const _SuggestionTile({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: AppAvatar(
          url: profile.avatarUrl,
          initials: profile.avatarInitials,
        ),
        title: Text(
          profile.displayName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('@${profile.username}'),
        trailing: _FollowButton(profile: profile),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserProfileScreen(username: profile.username),
          ),
        ),
      ),
    );
  }
}

class _FollowButton extends StatefulWidget {
  final Profile profile;
  const _FollowButton({required this.profile});

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _following = false;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _loading
          ? null
          : () async {
              if (!requireLogin(context)) return;
              setState(() => _loading = true);
              final res = await FollowService.instance.toggleFollow(
                widget.profile.id,
              );
              if (!mounted) return;
              setState(() {
                _loading = false;
                if (res.ok) _following = res.data ?? !_following;
              });
            },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        backgroundColor: _following ? const Color(0xFF1C1A24) : null,
        foregroundColor: _following ? Colors.white : null,
      ),
      child: Text(_following ? 'A seguir' : 'Seguir'),
    );
  }
}
