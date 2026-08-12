import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/fanfic.dart';
import '../../models/gallery_item.dart';
import '../../models/post.dart';
import '../../models/profile.dart';
import '../../models/conversation.dart';
import '../../services/follow_service.dart';
import '../../services/message_service.dart';
import '../../services/post_service.dart';
import '../../services/user_service.dart';
import '../../utils/access.dart';
import '../../utils/format.dart';
import '../../widgets/avatar.dart';
import '../../widgets/post_card.dart';
import '../../widgets/states.dart';
import '../messages/conversation_screen.dart';
import '../post/post_detail_screen.dart';

class ProfileView extends StatefulWidget {
  final Profile profile;
  final String username;
  final bool isOwn;
  final VoidCallback? onEdit;

  const ProfileView({
    super.key,
    required this.profile,
    required this.username,
    this.isOwn = false,
    this.onEdit,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Post> _posts = [];
  List<Fanfic> _fanfics = [];
  List<GalleryItem> _gallery = [];
  bool _loading = true;
  bool _following = false;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _following = widget.profile.followedByMe ?? widget.profile.isFollowing ?? false;
    _tabController = TabController(length: 3, vsync: this)..addListener(_onTab);
    _loadTab('posts');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _activeTab =>
      _tabController.index == 1 ? 'fanfics' : _tabController.index == 2 ? 'gallery' : 'posts';

  void _onTab() {
    _loadTab(_activeTab);
  }

  Future<void> _loadTab(String tab) async {
    if (tab == 'posts' && _posts.isNotEmpty) return;
    if (tab == 'fanfics' && _fanfics.isNotEmpty) return;
    if (tab == 'gallery' && _gallery.isNotEmpty) return;

    setState(() => _loading = true);
    final res = await UserService.instance.getByUsername(widget.username, tab: tab);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok && res.data != null) {
        if (tab == 'fanfics') {
          _fanfics = res.data!.data.cast<Fanfic>();
        } else if (tab == 'gallery') {
          _gallery = res.data!.data.cast<GalleryItem>();
        } else {
          _posts = res.data!.data.cast<Post>();
        }
      }
    });
  }

  Future<void> _toggleFollow() async {
    if (!requireLogin(context)) return;
    setState(() => _followLoading = true);
    final res = await FollowService.instance.toggleFollow(widget.profile.id);
    if (!mounted) return;
    setState(() {
      _followLoading = false;
      if (res.ok) _following = res.data ?? !_following;
    });
  }

  Future<void> _openChat(BuildContext context) async {
    if (!requireLogin(context)) return;
    final res = await MessageService.instance.getOrCreateConversation(widget.profile.id);
    if (!mounted) return;
    if (res.ok && res.data != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConversationScreen(
            conversation: Conversation(id: res.data!),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Erro ao abrir conversa.')),
      );
    }
  }

  void _showPostMenu(BuildContext context, Post post) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final p = widget.profile;
    final muted = (isDark ? AppColors.darkText : AppColors.lightText).withValues(alpha: 0.55);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, muted, isDark)),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: SizedBox(
              width: double.infinity,
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Publicações (${AppFormat.compactCount(p.postsCount)})'),
                  const Tab(text: 'Fanfics'),
                  const Tab(text: 'Galeria'),
                ],
              ),
            ),
          ),
          _buildTabSliver(),
        ],
      ),
    );
  }

  Widget _buildTabSliver() {
    if (_loading) {
      return const SliverFillRemaining(
        child: LoadingView(message: 'A carregar...'),
      );
    }
    if (_activeTab == 'fanfics') {
      if (_fanfics.isEmpty) {
        return SliverFillRemaining(
          child: EmptyView(message: 'Sem fanfics publicadas.', icon: Icons.menu_book_outlined),
        );
      }
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _FanficTile(fanfic: _fanfics[i]),
          ),
          childCount: _fanfics.length,
        ),
      );
    }
    if (_activeTab == 'gallery') {
      if (_gallery.isEmpty) {
        return SliverFillRemaining(
          child: EmptyView(message: 'Sem conteúdo na galeria.', icon: Icons.photo_library_outlined),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.all(12),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final item = _gallery[i];
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Container(
                    color: Colors.black26,
                    child: const Icon(Icons.broken_image, color: Colors.white54),
                  ),
                ),
              );
            },
            childCount: _gallery.length,
          ),
        ),
      );
    }
    if (_posts.isEmpty) {
      return SliverFillRemaining(
        child: const EmptyView(message: 'Sem publicações ainda.', icon: Icons.article_outlined),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final post = _posts[i];
          return PostCard(
            post: post,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
            ),
            onLike: () async {
              if (!requireLogin(context)) return;
              final res = await PostService.instance.toggleLike(post.id);
              if (!mounted || !res.ok) return;
              setState(() {
                final idx = _posts.indexWhere((p) => p.id == post.id);
                if (idx != -1) {
                  _posts[idx] = _posts[idx].copyWith(
                    likedByMe: res.data,
                    likesCount: _posts[idx].likesCount + ((res.data ?? false) ? 1 : -1),
                  );
                }
              });
            },
            onComment: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
            ),
            onRepost: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
            ),
            onShare: () {},
          onMore: () => _showPostMenu(context, post),
          );
        },
        childCount: _posts.length,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color muted, bool isDark) {
    final p = widget.profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.55),
                AppColors.pink.withValues(alpha: 0.35),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: p.coverUrl != null && p.coverUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: p.coverUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                )
              : null,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: const Offset(0, -28),
                child: AppAvatar(
                  url: p.avatarUrl,
                  initials: p.avatarInitials,
                  size: 84,
                  showOnline: true,
                  online: p.isOnline,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      p.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (p.role == 'superuser') ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.pink.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'SUPER',
                        style: TextStyle(
                          color: AppColors.pink,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ] else if (p.role == 'mod') ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'MOD',
                        style: TextStyle(
                          color: AppColors.accentSoft,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (widget.isOwn && widget.onEdit != null)
                    IconButton(
                      tooltip: 'Editar perfil',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: widget.onEdit,
                    )
                  else if (!widget.isOwn) ...[
                    _followLoading
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : FilledButton.tonal(
                            onPressed: _toggleFollow,
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  _following ? const Color(0xFF1C1A24) : null,
                              foregroundColor: _following ? Colors.white : null,
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                            ),
                            child: Text(_following ? 'A seguir' : 'Seguir'),
                          ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Mensagem',
                      icon: const Icon(Icons.message_outlined),
                      onPressed: () => _openChat(context),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text('@${p.username}', style: TextStyle(color: muted)),
              if (p.bio != null && p.bio!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(p.bio!, style: const TextStyle(fontSize: 14, height: 1.45)),
              ],
              if (p.location != null || p.website != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    if (p.location != null && p.location!.isNotEmpty)
                      _infoChip(context, Icons.place_outlined, p.location!),
                    if (p.website != null && p.website!.isNotEmpty)
                      _infoChip(context, Icons.link, p.website!),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  _count(context, p.postsCount, 'Publicações'),
                  _count(context, p.followersCount, 'Seguidores'),
                  _count(context, p.followingCount, 'A seguir'),
                  _count(context, p.likesReceivedCount, 'Gostos'),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _count(BuildContext context, int value, String label) {
    final muted = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5);
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppFormat.compactCount(value),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          Text(label, style: TextStyle(fontSize: 12.5, color: muted)),
        ],
      ),
    );
  }

  }

class _FanficTile extends StatelessWidget {
  final Fanfic fanfic;
  const _FanficTile({required this.fanfic});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fanfic.coverUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: fanfic.coverUrl!,
                  width: 56,
                  height: 80,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Container(
                    width: 56,
                    height: 80,
                    color: const Color(0xFF7C5CFC).withValues(alpha: 0.2),
                    child: const Icon(Icons.menu_book_outlined),
                  ),
                ),
              )
            else
              Container(
                width: 56,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_outlined, color: AppColors.accent),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fanfic.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  if (fanfic.fandom != null)
                    Text(
                      fanfic.fandom!,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFFE879F9)),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${fanfic.chapters} caps · ${AppFormat.compactCount(fanfic.words)} palavras · ${AppFormat.compactCount(fanfic.readsCount)} leituras',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusLabel(fanfic.status),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5CFCB4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'complete':
        return 'Completa';
      case 'hiatus':
        return 'Em pausa';
      default:
        return 'Em curso';
    }
  }
}
