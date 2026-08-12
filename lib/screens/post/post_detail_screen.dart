import 'package:flutter/material.dart';

import '../../models/comment.dart';
import '../../models/post.dart';
import '../../services/comment_service.dart';
import '../../services/post_service.dart';
import '../../utils/access.dart';
import '../../utils/format.dart';
import '../../utils/mentions.dart';
import '../../widgets/avatar.dart';
import '../../widgets/post_card.dart';
import '../../widgets/states.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Post? _post;
  List<Comment> _comments = [];
  bool _loading = true;
  bool _commentsLoading = true;
  String? _error;
  final TextEditingController _commentController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await PostService.instance.getPost(widget.postId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        _post = res.data;
      } else {
        _error = res.error;
      }
    });
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _commentsLoading = true);
    final res = await CommentService.instance.getComments(widget.postId);
    if (!mounted) return;
    setState(() {
      _commentsLoading = false;
      if (res.ok) _comments = res.data ?? [];
    });
  }

  Future<void> _toggleLike() async {
    final post = _post;
    if (post == null || !requireLogin(context)) return;
    final res = await PostService.instance.toggleLike(post.id);
    if (!mounted || !res.ok) return;
    final liked = res.data ?? false;
    setState(() {
      _post = post.copyWith(
        likedByMe: liked,
        likesCount: post.likesCount + (liked ? 1 : -1),
      );
    });
  }

  Future<void> _sendComment({String? parentId}) async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _sending) return;
    if (!requireLogin(context)) return;
    setState(() => _sending = true);
    final res = await CommentService.instance.addComment(
      widget.postId,
      text,
      parentId: parentId,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (res.ok) {
      _commentController.clear();
      setState(() {
        _comments.add(res.data!);
        _post = _post?.copyWith(commentsCount: (_post!.commentsCount + 1));
      });
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res.error ?? 'Erro.')));
    }
  }

  void _scrollToBottom() {}

  Future<void> _repost() async {
    final post = _post;
    if (post == null || !requireLogin(context)) return;
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Repostar'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 280,
          decoration: const InputDecoration(hintText: 'Adiciona um comentário (opcional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Repostar')),
        ],
      ),
    );
    if (ok == true) {
      final res = await PostService.instance.repostPost(post.id, content: controller.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.ok ? 'Publicação repostada!' : (res.error ?? 'Erro.'))),
      );
    }
  }

  Future<void> _share() async {
    final post = _post;
    if (post == null) return;
    final res = await PostService.instance.sharePost(post.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.error ?? 'Link copiado!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    final muted = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5);

    return Scaffold(
      appBar: AppBar(title: const Text('Publicação')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : post == null
                  ? const ErrorView(message: 'Publicação não encontrada.')
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(12),
                            children: [
                              PostCard(
                                post: post,
                                onTap: () {},
                                onLike: _toggleLike,
                                onComment: () => _focusComment(),
                                onRepost: _repost,
                                onShare: _share,
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  children: [
                                    Text(
                                      'Comentários',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: muted,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: _loadComments,
                                      child: const Text('Atualizar'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_commentsLoading)
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              else if (_comments.isEmpty)
                                const EmptyView(
                                  message: 'Seja o primeiro a comentar.',
                                  icon: Icons.mode_comment_outlined,
                                )
                              else
                                ..._comments.map((c) => _CommentTile(
                                      comment: c,
                                      onReply: () => _replyTo(c),
                                      onDelete: () => _deleteComment(c),
                                    )),
                            ],
                          ),
                        ),
                        _buildCommentBar(),
                      ],
                    ),
    );
  }

  void _focusComment() {}

  void _replyTo(Comment comment) {
    _commentController.text = '@${comment.author?.username ?? ''} ';
    setState(() {});
  }

  Future<void> _deleteComment(Comment comment) async {
    if (!requireLogin(context)) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar comentário'),
        content: const Text('Tens a certeza?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFC5C7D)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final res = await CommentService.instance.deleteComment(widget.postId, comment.id);
      if (!mounted) return;
      if (res.ok) {
        setState(() => _comments.removeWhere((c) => c.id == comment.id));
      }
    }
  }

  Widget _buildCommentBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                minLines: 1,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Escreve um comentário...',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sending ? null : _sendComment,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;

  const _CommentTile({required this.comment, this.onReply, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = comment.author;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (author != null)
            AppAvatar(
              url: author.avatarUrl,
              initials: author.avatarInitials,
              size: 34,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${author?.displayName ?? 'Utilizador'} · @${author?.username ?? ''}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        AppFormat.relativeTime(comment.createdAt),
                        style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText.rich(
                    TextSpan(
                      children: buildContentSpans(
                        comment.content,
                        base: TextStyle(fontSize: 14, height: 1.45, color: textColor),
                        brightness: theme.brightness,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      InkWell(
                        onTap: onReply,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            'Responder',
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: onDelete,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: const Text(
                              'Apagar',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFC5C7D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
