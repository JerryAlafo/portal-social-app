import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/gallery_item.dart';
import '../../services/gallery_service.dart';
import '../../services/upload_service.dart';
import '../../utils/access.dart';
import '../../widgets/states.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<GalleryItem> _items = [];
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
    final res = await GalleryService.instance.getGallery();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        _items = res.data ?? [];
      } else {
        _error = res.error;
      }
    });
  }

  Future<void> _openUploadModal() async {
    if (!requireLogin(context)) return;

    final titleController = TextEditingController();
    String category = 'Arte';
    File? imageFile;
    String? imagePreview;

    final picked = await showDialog<_PickedImage?>(
      context: context,
      builder: (ctx) => _PickImageDialog(),
    );

    if (picked == null) return;
    imageFile = picked.file;
    imagePreview = picked.preview;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _UploadFormDialog(
        titleController: titleController,
        category: category,
        imagePreview: imagePreview,
        onCategoryChanged: (v) => category = v ?? 'Arte',
      ),
    );

    if (result != true) return;

    setState(() => _loading = true);
    final title = titleController.text.trim();

    try {
      final bytes = await imageFile.readAsBytes();
      final filename = imageFile.path.split(Platform.pathSeparator).last;
      final uploadRes = await UploadService.instance.uploadImage(
        bytes: bytes,
        filename: filename,
        bucket: 'gallery',
      );

      if (!mounted) return;
      if (!uploadRes.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uploadRes.error ?? 'Erro no upload')),
        );
        setState(() => _loading = false);
        return;
      }

      final galleryRes = await GalleryService.instance.uploadGalleryItem(
        title: title,
        category: category,
        imageUrl: uploadRes.data!,
      );

      if (!mounted) return;
      setState(() => _loading = false);
      if (galleryRes.ok) {
        setState(() => _items.insert(0, galleryRes.data!));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicado na galeria!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(galleryRes.error ?? 'Erro')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao publicar na galeria.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Galeria')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openUploadModal,
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('Publicar'),
      ),
      body: _loading
          ? const LoadingView(message: 'A carregar galeria...')
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? const EmptyView(message: 'Sem publicações na galeria.', icon: Icons.photo_library_outlined)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final item = _items[i];
                          return GestureDetector(
                            onTap: () => _open(context, item),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: item.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const ColoredBox(
                                  color: Color(0x227C5CFC),
                                  child: Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => const ColoredBox(
                                  color: Color(0x227C5CFC),
                                  child: Center(child: Icon(Icons.broken_image_outlined)),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  void _open(BuildContext context, GalleryItem item) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GalleryViewScreen(item: item),
    ));
  }
}

class _PickedImage {
  final File file;
  final String preview;
  const _PickedImage({required this.file, required this.preview});
}

class _PickImageDialog extends StatefulWidget {
  const _PickImageDialog();

  @override
  State<_PickImageDialog> createState() => _PickImageDialogState();
}

class _PickImageDialogState extends State<_PickImageDialog> {
  File? _file;
  String? _preview;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Escolher Imagem'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_preview != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_preview!),
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1024,
                imageQuality: 85,
              );
              if (picked != null && mounted) {
                setState(() {
                  _file = File(picked.path);
                  _preview = picked.path;
                });
              }
            },
            icon: const Icon(Icons.image),
            label: Text(_file != null ? 'Alterar imagem' : 'Escolher imagem'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _file == null
              ? null
              : () => Navigator.pop(context, _PickedImage(file: _file!, preview: _preview!)),
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}

class _UploadFormDialog extends StatelessWidget {
  final TextEditingController titleController;
  final String category;
  final String? imagePreview;
  final ValueChanged<String?> onCategoryChanged;

  const _UploadFormDialog({
    required this.titleController,
    required this.category,
    required this.imagePreview,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detalhes da Publicação'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePreview != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(imagePreview!),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Título *'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: const [
                DropdownMenuItem(value: 'Arte', child: Text('Arte')),
                DropdownMenuItem(value: 'Cosplay', child: Text('Cosplay')),
                DropdownMenuItem(value: 'Screenshots', child: Text('Screenshots')),
                DropdownMenuItem(value: 'Fanart', child: Text('Fanart')),
                DropdownMenuItem(value: 'Figura', child: Text('Figura')),
              ],
              onChanged: onCategoryChanged,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (titleController.text.trim().isEmpty) return;
            Navigator.pop(context, true);
          },
          child: const Text('Publicar'),
        ),
      ],
    );
  }
}

class GalleryViewScreen extends StatefulWidget {
  final GalleryItem item;
  const GalleryViewScreen({super.key, required this.item});

  @override
  State<GalleryViewScreen> createState() => _GalleryViewScreenState();
}

class _GalleryViewScreenState extends State<GalleryViewScreen> {
  bool _liked = false;
  int _likes = 0;

  @override
  void initState() {
    super.initState();
    _likes = widget.item.likesCount;
    _loadLiked();
  }

  Future<void> _loadLiked() async {
    final res = await GalleryService.instance.getLikedIds();
    if (!mounted || !res.ok) return;
    setState(() => _liked = (res.data ?? []).contains(widget.item.id));
  }

  Future<void> _toggleLike() async {
    final target = !_liked;
    setState(() {
      _liked = target;
      _likes += target ? 1 : -1;
    });
    final res = await GalleryService.instance.toggleLike(widget.item.id);
    if (!mounted) return;
    if (res.ok) {
      setState(() => _likes = res.data ?? _likes);
    } else {
      setState(() {
        _liked = !target;
        _likes += target ? -1 : 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 60, color: Colors.white54),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (item.author != null)
                    Expanded(
                      child: Text(
                        '@${item.author!.username}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  IconButton(
                    onPressed: _toggleLike,
                    icon: Icon(
                      _liked ? Icons.favorite : Icons.favorite_border,
                      color: _liked ? const Color(0xFFFC5C7D) : Colors.white,
                    ),
                  ),
                  Text(
                    '$_likes',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
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
