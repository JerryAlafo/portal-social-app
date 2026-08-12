import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../services/post_service.dart';
import '../../services/upload_service.dart';
import '../../widgets/states.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _controller = TextEditingController();
  String _category = 'Outro';
  bool _spoiler = false;
  bool _sensitive = false;
  File? _image;
  bool _uploading = false;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _submitting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escreve alguma coisa antes de publicar.')),
      );
      return;
    }

    setState(() => _submitting = true);

    String? imageUrl;
    if (_image != null) {
      setState(() => _uploading = true);
      final bytes = await _image!.readAsBytes();
      final upload = await UploadService.instance.uploadImage(
        bytes: bytes,
        filename: _image!.path.split(Platform.pathSeparator).last,
        bucket: 'posts',
      );
      if (!mounted) return;
      if (!upload.ok) {
        setState(() {
          _submitting = false;
          _uploading = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(upload.error ?? 'Erro ao fazer upload.')));
        return;
      }
      imageUrl = upload.data;
    }

    final res = await PostService.instance.createPost(
      content: content,
      category: _category,
      imageUrl: imageUrl,
      isSpoiler: _spoiler,
      isSensitive: _sensitive,
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.ok) {
      Navigator.of(context).pop(res.data);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res.error ?? 'Erro ao publicar.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova publicação'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Publicar'),
            ),
          ),
        ],
      ),
      body: _uploading
          ? const LoadingView(message: 'A enviar imagem...')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: 6,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: 'O que se passa no teu mundo?',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: const [
                    'Shonen', 'Shojo', 'Isekai', 'Seinen', 'Cosplay',
                    'Manga', 'Figura', 'AMV', 'Outro',
                  ]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v ?? 'Outro'),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  value: _spoiler,
                  onChanged: (v) => setState(() => _spoiler = v),
                  title: const Text('Contém spoilers'),
                  subtitle: const Text('O conteúdo ficará oculto até revelar'),
                  secondary: const Icon(Icons.visibility_off_outlined, color: AppColors.warning),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                SwitchListTile(
                  value: _sensitive,
                  onChanged: (v) => setState(() => _sensitive = v),
                  title: const Text('Conteúdo sensível'),
                  subtitle: const Text('Aviso de conteúdo sensível'),
                  secondary: const Icon(Icons.warning_amber_outlined, color: AppColors.danger),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                const SizedBox(height: 16),
                if (_image == null)
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Adicionar imagem'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  )
                else
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _image!,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton.filled(
                          style: IconButton.styleFrom(backgroundColor: Colors.black54),
                          onPressed: () => setState(() => _image = null),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}
