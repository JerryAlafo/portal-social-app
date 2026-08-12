import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/conversation.dart';
import '../../models/post.dart';
import '../../models/profile.dart';
import '../../models/trending_tag.dart';
import '../../services/message_service.dart';
import '../../services/search_service.dart';
import '../../utils/access.dart';
import '../../widgets/avatar.dart';
import '../../widgets/post_card.dart';
import '../../widgets/states.dart';
import '../messages/conversation_screen.dart';
import '../perfil/user_profile_screen.dart';
import '../post/post_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _type = 'all';
  List<Post> _posts = [];
  List<Profile> _users = [];
  List<TrendingTag> _trending = [];
  bool _loading = false;
  bool _searched = false;
  bool _loadingTrending = false;

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadTrending() async {
    setState(() => _loadingTrending = true);
    final res = await SearchService.instance.search('', type: 'all');
    if (!mounted) return;
    setState(() {
      _loadingTrending = false;
      if (res.ok && res.data != null) {
        _trending = res.data!.tags;
      }
    });
  }

  Future<void> _search(String q) async {
    q = q.trim();
    setState(() {
      _loading = true;
      _searched = true;
    });
    final res = await SearchService.instance.search(q, type: _type);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok && res.data != null) {
        _posts = res.data!.posts;
        _users = res.data!.users;
      }
    });
  }

  Future<void> _openChat(Profile user) async {
    if (!requireLogin(context)) return;
    final res = await MessageService.instance.getOrCreateConversation(user.id);
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
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: false,
          decoration: const InputDecoration(hintText: 'Pesquisar anime, membros, tags...', border: InputBorder.none),
          textInputAction: TextInputAction.search,
          onSubmitted: (q) => q.trim().isNotEmpty ? _search(q) : null,
        ),
        actions: [
          IconButton(
            onPressed: () => _controller.text.trim().isNotEmpty ? _search(_controller.text) : null,
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('Tudo')),
                ButtonSegment(value: 'posts', label: Text('Publicações')),
                ButtonSegment(value: 'users', label: Text('Membros')),
                ButtonSegment(value: 'tags', label: Text('Tags')),
              ],
              selected: {_type},
              onSelectionChanged: (s) {
                setState(() {
                  _type = s.first;
                  _posts = [];
                  _users = [];
                  _searched = false;
                });
                if (_controller.text.trim().isNotEmpty) _search(_controller.text);
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : !_searched
                    ? _buildTrending()
                    : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrending() {
    if (_loadingTrending) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_trending.isEmpty) {
      return const EmptyView(
        message: 'Pesquisa por utilizadores ou publicações.',
        icon: Icons.search,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            const Icon(Icons.trending_up, size: 18, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              'Em destaque agora',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._trending.map((t) => InkWell(
              onTap: () {
                _controller.text = t.tag;
                _search(t.tag);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Row(
                  children: [
                    const Icon(Icons.tag, size: 16, color: AppColors.accentSoft),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${t.tag}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Text(
                            '${t.postCount} publicações',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildResults() {
    final hasQuery = _controller.text.trim().isNotEmpty;
    final showPosts = _type == 'all' || _type == 'posts';
    final showUsers = _type == 'all' || _type == 'users';
    final showTags = _type == 'all' || _type == 'tags';

    if (!hasQuery && _posts.isEmpty && _users.isEmpty) {
      return _buildTrending();
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (showUsers && _users.isNotEmpty) ...[
          Text(
            'Membros',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          ..._users.map((u) => ListTile(
                leading: AppAvatar(
                  url: u.avatarUrl,
                  initials: u.avatarInitials,
                  size: 42,
                  showOnline: true,
                  online: u.isOnline,
                ),
                title: Text(u.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('@${u.username}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _openChat(u),
                      icon: const Icon(Icons.message_outlined, size: 18),
                      tooltip: 'Mensagem',
                    ),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserProfileScreen(username: u.username),
                  ),
                ),
              )),
          const SizedBox(height: 16),
        ],
        if (showTags && _trending.isNotEmpty && hasQuery) ...[
          Text(
            'Tags',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _trending.map((t) => ActionChip(
                  label: Text('#${t.tag}'),
                  onPressed: () {
                    _controller.text = t.tag;
                    _search(t.tag);
                  },
                )).toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (showPosts && _posts.isNotEmpty) ...[
          Text(
            'Publicações',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          ..._posts.map((p) => PostCard(
                post: p,
                onMore: () => _showPostMenu(context, p),
              )),
        ],
        if (_posts.isEmpty && _users.isEmpty && hasQuery)
          const EmptyView(message: 'Sem resultados.', icon: Icons.search_off),
      ],
    );
  }
}
