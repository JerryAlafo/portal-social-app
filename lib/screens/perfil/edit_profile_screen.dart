import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../models/profile.dart';
import '../../services/profile_service.dart';
import '../../services/upload_service.dart';
import '../../widgets/avatar.dart';
import '../../widgets/states.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _displayName;
  late final TextEditingController _bio;
  late final TextEditingController _location;
  late final TextEditingController _website;

  File? _avatarFile;
  File? _coverFile;
  String? _avatarUrl;
  String? _coverUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _displayName = TextEditingController(text: p.displayName);
    _bio = TextEditingController(text: p.bio ?? '');
    _location = TextEditingController(text: p.location ?? '');
    _website = TextEditingController(text: p.website ?? '');
    _avatarUrl = p.avatarUrl;
    _coverUrl = p.coverUrl;
  }

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    _location.dispose();
    _website.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isAvatar) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (isAvatar) {
      setState(() => _avatarFile = File(picked.path));
    } else {
      setState(() => _coverFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final updates = <String, dynamic>{
      'display_name': _displayName.text.trim(),
      'bio': _bio.text.trim(),
      'location': _location.text.trim(),
      'website': _website.text.trim(),
    };

    if (_avatarFile != null) {
      final bytes = await _avatarFile!.readAsBytes();
      final upload = await UploadService.instance.uploadImage(
        bytes: bytes,
        filename: 'avatar.jpg',
        bucket: 'avatars',
      );
      if (upload.ok) updates['avatar_url'] = upload.data;
    }
    if (_coverFile != null) {
      final bytes = await _coverFile!.readAsBytes();
      final upload = await UploadService.instance.uploadImage(
        bytes: bytes,
        filename: 'cover.jpg',
        bucket: 'covers',
      );
      if (upload.ok) updates['cover_url'] = upload.data;
    }

    final res = await ProfileService.instance.updateProfile(updates);
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado!')),
      );
      Navigator.of(context).pop(res.data);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res.error ?? 'Erro ao atualizar.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final muted = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar'),
            ),
          ),
        ],
      ),
      body: _saving
          ? const LoadingView(message: 'A guardar...')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Cover
                Stack(
                  children: [
                    Container(
                      height: 130,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C5CFC), Color(0xFFE879F9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: _coverFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(_coverFile!, fit: BoxFit.cover),
                            )
                          : (_coverUrl?.isNotEmpty ?? false)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(_coverUrl!, fit: BoxFit.cover),
                                )
                              : null,
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
                        onPressed: () => _pickImage(false),
                        icon: const Icon(Icons.photo_camera_outlined, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      _avatarFile != null
                          ? ClipOval(
                              child: Image.file(
                                _avatarFile!,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                              ),
                            )
                          : AppAvatar(
                              url: _avatarUrl,
                              initials: p.avatarInitials,
                              size: 88,
                            ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.all(6),
                          ),
                          onPressed: () => _pickImage(true),
                          icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Nome de display', style: TextStyle(color: muted, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _displayName,
                  decoration: const InputDecoration(hintText: 'O teu nome'),
                ),
                const SizedBox(height: 16),
                Text('Bio (máx. 160)', style: TextStyle(color: muted, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _bio,
                  maxLines: 3,
                  maxLength: 160,
                  decoration: const InputDecoration(hintText: 'Conta-nos sobre ti'),
                ),
                const SizedBox(height: 16),
                Text('Localização', style: TextStyle(color: muted, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _location,
                  decoration: const InputDecoration(hintText: 'Cidade, país'),
                ),
                const SizedBox(height: 16),
                Text('Website', style: TextStyle(color: muted, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _website,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(hintText: 'https://'),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
