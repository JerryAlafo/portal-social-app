import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/fanfic.dart';
import '../../services/fanfic_service.dart';
import '../../utils/access.dart';
import '../../widgets/states.dart';
import 'fanfic_reader_screen.dart';

class FanficsScreen extends StatefulWidget {
  const FanficsScreen({super.key});

  @override
  State<FanficsScreen> createState() => _FanficsScreenState();
}

class _FanficsScreenState extends State<FanficsScreen> {
  List<Fanfic> _fanfics = [];
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
    final res = await FanficService.instance.getFanfics();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        _fanfics = res.data ?? [];
      } else {
        _error = res.error;
      }
    });
  }

  Future<void> _openCreateModal() async {
    if (!requireLogin(context)) return;

    final titleController = TextEditingController();
    final summaryController = TextEditingController();
    final fandomController = TextEditingController();
    final genreController = TextEditingController();
    String status = 'Em curso';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Nova Fanfic'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Título *'),
                ),
                TextField(
                  controller: summaryController,
                  decoration: const InputDecoration(labelText: 'Resumo *'),
                  maxLines: 5,
                ),
                TextField(
                  controller: fandomController,
                  decoration: const InputDecoration(labelText: 'Fandom *'),
                ),
                TextField(
                  controller: genreController,
                  decoration: const InputDecoration(labelText: 'Género *'),
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(value: 'Em curso', child: Text('Em curso')),
                    DropdownMenuItem(value: 'Completo', child: Text('Completo')),
                    DropdownMenuItem(value: 'Pausado', child: Text('Pausado')),
                  ],
                  onChanged: (v) => setModalState(() => status = v ?? 'Em curso'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    summaryController.text.trim().isEmpty ||
                    fandomController.text.trim().isEmpty ||
                    genreController.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Publicar'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    setState(() => _loading = true);
    final res = await FanficService.instance.createFanfic(
      title: titleController.text.trim(),
      summary: summaryController.text.trim(),
      fandom: fandomController.text.trim(),
      genre: genreController.text.trim(),
      status: status,
    );

    if (!mounted) return;
    setState(() => _loading = false);
    if (res.ok) {
      setState(() => _fanfics.insert(0, res.data!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fanfic publicada!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Erro')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fanfics')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateModal,
        icon: const Icon(Icons.add),
        label: const Text('Publicar fanfic'),
      ),
      body: _loading
          ? const LoadingView(message: 'A carregar fanfics...')
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _fanfics.isEmpty
                  ? const EmptyView(message: 'Sem fanfics publicadas.', icon: Icons.menu_book_outlined)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _fanfics.length,
                        itemBuilder: (context, i) => _FanficCard(fanfic: _fanfics[i]),
                      ),
                    ),
    );
  }
}

class _FanficCard extends StatelessWidget {
  final Fanfic fanfic;
  const _FanficCard({required this.fanfic});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FanficReaderScreen(fanfic: fanfic)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: fanfic.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: fanfic.coverUrl!,
                        width: 64,
                        height: 88,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => _coverPlaceholder(),
                      )
                    : _coverPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fanfic.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
                    ),
                    if (fanfic.author != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'por @${fanfic.author!.username}',
                        style: TextStyle(fontSize: 12.5, color: AppColors.accentSoft),
                      ),
                    ],
                    if (fanfic.synopsis != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        fanfic.synopsis!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: muted, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (fanfic.genre != null) ...[
                          _chip(fanfic.genre!),
                          const SizedBox(width: 6),
                        ],
                        if (fanfic.fandom != null) ...[
                          _chip(fanfic.fandom!),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '${fanfic.readsCount} leituras',
                          style: TextStyle(fontSize: 11.5, color: muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      width: 64,
      height: 88,
      color: AppColors.accent.withValues(alpha: 0.15),
      child: const Icon(Icons.menu_book, color: AppColors.accent, size: 28),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.accentSoft, fontWeight: FontWeight.w600),
      ),
    );
  }
}
