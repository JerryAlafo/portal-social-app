import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/post.dart';
import '../utils/format.dart';
import '../utils/mentions.dart';
import 'avatar.dart';

typedef PostAction = void Function(Post post);

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onRepost;
  final VoidCallback? onShare;
  final VoidCallback? onMore;
  final bool showActions;
  final bool compact;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onRepost,
    this.onShare,
    this.onMore,
    this.showActions = true,
    this.compact = false,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _spoilerRevealed = false;
  bool _sensitiveRevealed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = textColor.withValues(alpha: 0.55);
    final small = MediaQuery.sizeOf(context).width < 600;

    final padding = small ? const EdgeInsets.all(12) : EdgeInsets.all(widget.compact ? 12 : 16);
    final nameStyle = small
        ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)
        : const TextStyle(fontWeight: FontWeight.w700, fontSize: 15);
    final metaStyle = small
        ? TextStyle(fontSize: 12, color: muted)
        : TextStyle(fontSize: 13, color: muted);
    final contentStyle = TextStyle(
      fontSize: small ? 14 : 15,
      height: small ? 1.45 : 1.5,
      color: textColor,
    );

    final displayPost = widget.post.repost ?? widget.post;
    final author = displayPost.author;
    final isRepost = widget.post.repost != null;
    final isSpoiler = displayPost.isSpoiler == true;
    final isSensitive = displayPost.isSensitive == true;
    final isHidden = (isSpoiler && !_spoilerRevealed) || (isSensitive && !_sensitiveRevealed);

    final content = GestureDetector(
      onTap: widget.onTap,
      child: SelectableText.rich(
        TextSpan(
          children: buildContentSpans(
            displayPost.content,
            base: contentStyle,
            brightness: theme.brightness,
          ),
        ),
        onTap: widget.onTap,
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isRepost) ...[
                Row(
                  children: [
                    Icon(Icons.repeat, size: 14, color: muted),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.post.author?.displayName ?? ''} repostou',
                      style: TextStyle(fontSize: 12.5, color: muted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (author != null)
                    GestureDetector(
                      onTap: widget.onTap,
                      child: AppAvatar(
                        url: author.avatarUrl,
                        initials: author.avatarInitials,
                        size: widget.compact ? 36 : (small ? 38 : 42),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                author?.displayName ?? 'Utilizador',
                                overflow: TextOverflow.ellipsis,
                                style: nameStyle,
                              ),
                            ),
                            if (author?.role == 'superuser')
                              const SizedBox(width: 6),
                            if (author?.role == 'superuser')
                              _RoleBadge(
                                label: 'SUPER',
                                color: AppColors.pink,
                                isDark: isDark,
                              ),
                            if (author?.role == 'mod')
                              const SizedBox(width: 6),
                            if (author?.role == 'mod')
                              _RoleBadge(
                                label: 'MOD',
                                color: AppColors.accent,
                                isDark: isDark,
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${author?.username ?? ''} · ${AppFormat.relativeTime(displayPost.createdAt)}',
                          style: metaStyle,
                        ),
                      ],
                    ),
                  ),
                  if (widget.onMore != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.more_horiz, color: muted, size: 20),
                      onPressed: widget.onMore,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (isHidden)
                _SpoilerOverlay(
                  label: isSpoiler ? 'Spoiler' : 'Conteúdo sensível',
                  icon: isSpoiler ? Icons.visibility_off : Icons.warning_amber_rounded,
                  onReveal: () {
                    if (isSpoiler) {
                      setState(() => _spoilerRevealed = true);
                    } else {
                      setState(() => _sensitiveRevealed = true);
                    }
                  },
                )
              else ...[
                if (displayPost.category != null && displayPost.category!.isNotEmpty) ...[
                  _CategoryTag(label: displayPost.category!),
                  const SizedBox(height: 8),
                ],
                content,
                if (displayPost.imageUrl != null && displayPost.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _PostImage(
                    url: displayPost.imageUrl!,
                    spoiler: isSpoiler && !_spoilerRevealed,
                    sensitive: isSensitive && !_sensitiveRevealed,
                    onRevealSpoiler: () => setState(() => _spoilerRevealed = true),
                    onRevealSensitive: () => setState(() => _sensitiveRevealed = true),
                  ),
                ],
                if (widget.showActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _ActionButton(
                        icon: widget.post.likedByMe == true ? Icons.favorite : Icons.favorite_border,
                        color: widget.post.likedByMe == true ? AppColors.danger : muted,
                        label: AppFormat.compactCount(displayPost.likesCount),
                        onTap: widget.onLike,
                      ),
                      const SizedBox(width: 4),
                      _ActionButton(
                        icon: Icons.chat_bubble_outline,
                        color: muted,
                        label: AppFormat.compactCount(displayPost.commentsCount),
                        onTap: widget.onComment,
                      ),
                      const SizedBox(width: 4),
                      _ActionButton(
                        icon: Icons.repeat,
                        color: isRepost ? AppColors.success : muted,
                        label: AppFormat.compactCount(displayPost.sharesCount),
                        onTap: widget.onRepost,
                      ),
                      const Spacer(),
                      _ActionButton(
                        icon: Icons.share_outlined,
                        color: muted,
                        label: '',
                        onTap: widget.onShare,
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SpoilerOverlay extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onReveal;

  const _SpoilerOverlay({
    required this.label,
    required this.icon,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onReveal,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$label. Toque para revelar',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final String label;
  const _CategoryTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accentSoft,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  const _RoleBadge({required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PostImage extends StatelessWidget {
  final String url;
  final bool spoiler;
  final bool sensitive;
  final VoidCallback? onRevealSpoiler;
  final VoidCallback? onRevealSensitive;

  const _PostImage({
    required this.url,
    required this.spoiler,
    required this.sensitive,
    this.onRevealSpoiler,
    this.onRevealSensitive,
  });

  @override
  Widget build(BuildContext context) {
    final needsReveal = (spoiler && onRevealSpoiler != null) || (sensitive && onRevealSensitive != null);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImage(
              imageUrl: url,
              width: double.infinity,
              fit: BoxFit.contain,
              placeholder: (_, __) => Container(
                color: Colors.black26,
                child: const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Colors.black26,
                child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
              ),
            ),
          ),
          if (needsReveal)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (spoiler && onRevealSpoiler != null) {
                    onRevealSpoiler!();
                  } else if (sensitive && onRevealSensitive != null) {
                    onRevealSensitive!();
                  }
                },
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              spoiler ? Icons.visibility_off : Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              spoiler ? 'Spoiler' : 'Conteúdo sensível',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Toque para revelar',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
