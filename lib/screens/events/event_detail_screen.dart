import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/comment.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../utils/access.dart';
import '../../utils/format.dart';
import '../../widgets/avatar.dart';
import '../../widgets/states.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Event _event;
  List<EventComment> _comments = [];
  final _controller = TextEditingController();
  bool _commentsLoading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _commentsLoading = true);
    final res = await EventService.instance.getComments(_event.id);
    if (!mounted) return;
    setState(() {
      _commentsLoading = false;
      if (res.ok) _comments = res.data ?? [];
    });
  }

  Future<void> _toggleInterest(String type) async {
    if (!requireLogin(context)) return;
    final res = await EventService.instance.toggleInterest(_event.id, type);
    if (!mounted || !res.ok) return;
    final newType = res.data;
    setState(() {
      if (newType == 'interested') {
        _event = Event(
          id: _event.id,
          title: _event.title,
          description: _event.description,
          date: _event.date,
          location: _event.location,
          imageUrl: _event.imageUrl,
          organizerId: _event.organizerId,
          interestedCount: _event.interestedCount + 1,
          goingCount: _event.goingCount,
          dateColor: _event.dateColor,
          createdAt: _event.createdAt,
          organizer: _event.organizer,
          interestedByMe: true,
          goingByMe: false,
          commentsCount: _event.commentsCount,
        );
      } else if (newType == 'going') {
        _event = Event(
          id: _event.id,
          title: _event.title,
          description: _event.description,
          date: _event.date,
          location: _event.location,
          imageUrl: _event.imageUrl,
          organizerId: _event.organizerId,
          interestedCount: _event.interestedByMe == true
              ? _event.interestedCount - 1
              : _event.interestedCount,
          goingCount: _event.goingCount + 1,
          dateColor: _event.dateColor,
          createdAt: _event.createdAt,
          organizer: _event.organizer,
          interestedByMe: false,
          goingByMe: true,
          commentsCount: _event.commentsCount,
        );
      } else {
        _event = Event(
          id: _event.id,
          title: _event.title,
          description: _event.description,
          date: _event.date,
          location: _event.location,
          imageUrl: _event.imageUrl,
          organizerId: _event.organizerId,
          interestedCount: _event.interestedByMe == true
              ? _event.interestedCount - 1
              : _event.interestedCount,
          goingCount: _event.goingByMe == true ? _event.goingCount - 1 : _event.goingCount,
          dateColor: _event.dateColor,
          createdAt: _event.createdAt,
          organizer: _event.organizer,
          interestedByMe: false,
          goingByMe: false,
          commentsCount: _event.commentsCount,
        );
      }
    });
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    if (!requireLogin(context)) return;
    setState(() => _sending = true);
    final res = await EventService.instance.addComment(_event.id, text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (res.ok) {
      _controller.clear();
      setState(() => _comments.add(res.data!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(_event.date)?.toLocal();
    final muted = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5);

    return Scaffold(
      appBar: AppBar(title: const Text('Evento')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_event.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: _event.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(
                  height: 180,
                  color: AppColors.accent.withValues(alpha: 0.15),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            _event.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (dt != null)
            _info(Icons.calendar_today_outlined,
                '${dt.day}/${dt.month}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'),
          if (_event.location != null && _event.location!.isNotEmpty)
            _info(Icons.place_outlined, _event.location!),
          if (_event.organizer != null)
            _info(Icons.person_outline, 'Organizado por @${_event.organizer!.username}'),
          const SizedBox(height: 8),
          Text(
            '${_event.interestedCount} interessados · ${_event.goingCount} vão',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _toggleInterest('interested'),
                  icon: Icon(
                    _event.interestedByMe == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 18,
                  ),
                  label: Text(_event.interestedByMe == true ? 'Interessado' : 'Interessado'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _event.interestedByMe == true
                        ? const Color(0xFFE879F9).withValues(alpha: 0.2)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _toggleInterest('going'),
                  icon: Icon(
                    _event.goingByMe == true ? Icons.check : Icons.event_available,
                    size: 18,
                  ),
                  label: Text(_event.goingByMe == true ? 'A ir' : 'Vou'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _event.goingByMe == true
                        ? AppColors.success.withValues(alpha: 0.25)
                        : AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          if (_event.description != null && _event.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(_event.description!, style: const TextStyle(fontSize: 14.5, height: 1.5)),
          ],
          const SizedBox(height: 20),
          Text(
            'Comentários',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: muted),
          ),
          const SizedBox(height: 8),
          if (_commentsLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_comments.isEmpty)
            const EmptyView(message: 'Sem comentários.', icon: Icons.mode_comment_outlined)
          else
            ..._comments.map((c) => _CommentRow(comment: c)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Comenta o evento...'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : _sendComment,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    final muted = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  final EventComment comment;
  const _CommentRow({required this.comment});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            url: comment.author?.avatarUrl,
            initials: comment.author?.avatarInitials ?? '?',
            size: 32,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment.author?.displayName ?? 'Utilizador',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      Text(
                        AppFormat.relativeTime(comment.createdAt),
                        style: TextStyle(fontSize: 11, color: muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.content, style: const TextStyle(fontSize: 14, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
