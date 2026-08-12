import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/api_response.dart';
import '../../models/announcement.dart';
import '../../models/author.dart';
import '../../models/event.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../utils/format.dart';
import '../../widgets/avatar.dart';
import '../../widgets/states.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  int _tab = 0;
  late final TabController _tabController;
  AdminDashboard? _dashboard;
  List<Author> _users = [];
  List<Announcement> _announcements = [];
  List<Event> _events = [];
  String? _roleFilter;
  final _searchController = TextEditingController();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadDashboard();
  }

  void _onTabChanged() {
    final index = _tabController.index;
    if (index != _tab) {
      setState(() => _tab = index);
      if (index == 1 && _users.isEmpty) _loadUsers();
      if (index == 2 && _announcements.isEmpty) _loadAnnouncements();
      if (index == 3 && _events.isEmpty) _loadEvents();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await AdminService.instance.getDashboard();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        _dashboard = res.data;
      } else {
        _error = res.error;
      }
    });
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await AdminService.instance
        .getUsers(role: _roleFilter, search: _searchController.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        _users = res.data?.users ?? [];
      } else {
        _error = res.error;
      }
    });
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await AdminService.instance.getAnnouncements();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        _announcements = res.data ?? [];
      } else {
        _error = res.error;
      }
    });
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await AdminService.instance.getAdminEvents();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        _events = res.data ?? [];
      } else {
        _error = res.error;
      }
    });
  }

  Future<void> _processReport(AdminReport report, String action) async {
    final res = await AdminService.instance.processReport(report.id, action);
    if (!mounted) return;
    if (res.ok) {
      setState(() => _dashboard?.reports.removeWhere((r) => r.id == report.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(action == 'dismiss' ? 'Denúncia ignorada.' : 'Publicação eliminada.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Erro')));
    }
  }

  Future<void> _cycleRole(String userId, String direction) async {
    final Author user;
    try {
      user = _users.firstWhere((u) => u.id == userId);
    } on StateError {
      return;
    }
    final currentRole = user.role ?? 'member';
    const order = ['member', 'mod', 'superuser'];
    final idx = order.indexOf(currentRole);
    final newIdx = direction == 'up' ? min(idx + 1, 2) : max(idx - 1, 0);
    final newRole = order[newIdx];

    final auth = context.read<AuthService>();
    if (newRole == 'superuser' && auth.profile?.role != 'superuser') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apenas superusers podem atribuir superuser.')),
      );
      return;
    }

    final res = await AdminService.instance.updateUserRole(userId, newRole);
    if (!mounted) return;
    if (res.ok) {
      setState(() {
        _users = _users.map((u) => u.id == userId ? Author(id: u.id, username: u.username, displayName: u.displayName, avatarInitials: u.avatarInitials, avatarUrl: u.avatarUrl, role: newRole, isOnline: u.isOnline) : u).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newRole == 'superuser' ? 'Promovido a Superuser.' : newRole == 'mod' ? 'Promovido a Mod.' : 'Rebaixado para Membro.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Erro')));
    }
  }

  Future<void> _banUser(String userId, String userName) async {
    final reasonController = TextEditingController();
    final durationController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Banir Utilizador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tens a certeza que queres banir $userName?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Motivo', hintText: 'Ex: Spam'),
            ),
            TextField(
              controller: durationController,
              decoration: const InputDecoration(labelText: 'Dias (vazio = permanente)', hintText: 'Ex: 7'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFC5C7D)),
            child: const Text('Banir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final durationDays = int.tryParse(durationController.text.trim());
    final res = await AdminService.instance.banUser(
      userId,
      reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
      durationDays: durationDays,
    );
    if (!mounted) return;
    if (res.ok) {
      setState(() => _users.removeWhere((u) => u.id == userId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilizador banido com sucesso.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Erro')));
    }
  }

  Future<void> _deleteUser(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Conta'),
        content: Text('Tens a certeza que queres eliminar permanentemente a conta de $userName? Esta ação é irreversível.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFC5C7D)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final res = await AdminService.instance.deleteUser(userId);
    if (!mounted) return;
    if (res.ok) {
      setState(() => _users.removeWhere((u) => u.id == userId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta eliminada com sucesso.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Erro')));
    }
  }

  Future<void> _openAnnouncementModal([Announcement? announcement]) async {
    final isEdit = announcement != null;
    final titleController = TextEditingController(text: announcement?.title ?? '');
    final contentController = TextEditingController(text: announcement?.content ?? '');
    String status = announcement?.status ?? 'draft';
    bool pinned = announcement?.pinned ?? false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text(isEdit ? 'Editar Anúncio' : 'Criar Anúncio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título *'),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Conteúdo'),
                maxLines: 4,
              ),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Rascunho')),
                  DropdownMenuItem(value: 'published', child: Text('Publicado')),
                  DropdownMenuItem(value: 'archived', child: Text('Arquivado')),
                ],
                onChanged: (v) => setModalState(() => status = v ?? 'draft'),
              ),
              CheckboxListTile(
                value: pinned,
                title: const Text('Fixo no topo'),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setModalState(() => pinned = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: Text(isEdit ? 'Guardar' : 'Criar'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final title = titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _loading = true);
    ApiResult<Announcement> res;
    if (isEdit) {
      res = await AdminService.instance.updateAnnouncement(
        id: announcement.id,
        title: title,
        content: contentController.text.trim().isEmpty ? null : contentController.text.trim(),
        status: status,
        pinned: pinned,
      );
    } else {
      res = await AdminService.instance.createAnnouncement(
        title: title,
        content: contentController.text.trim().isEmpty ? null : contentController.text.trim(),
        status: status,
        pinned: pinned,
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);
    if (res.ok) {
      if (isEdit) {
        setState(() {
          _announcements = _announcements.map((a) => a.id == res.data!.id ? res.data! : a).toList();
        });
      } else {
        setState(() => _announcements.insert(0, res.data!));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Anúncio atualizado.' : 'Anúncio criado.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Erro')));
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Anúncio'),
        content: const Text('Tens a certeza que queres eliminar este anúncio?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFC5C7D)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final res = await AdminService.instance.deleteAnnouncement(id);
    if (!mounted) return;
    if (res.ok) {
      setState(() => _announcements.removeWhere((a) => a.id == id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anúncio eliminado.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Erro')));
    }
  }

  Future<void> _openEventModal([Event? event]) async {
    final isEdit = event != null;
    final titleController = TextEditingController(text: event?.title ?? '');
    final descController = TextEditingController(text: event?.description ?? '');
    final dateController = TextEditingController(text: event?.date != null ? event!.date.substring(0, 16) : '');
    final locationController = TextEditingController(text: event?.location ?? '');
    String dateColor = event?.dateColor ?? '#7C5CFC';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text(isEdit ? 'Editar Evento' : 'Criar Evento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título *'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
              ),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Data *'),
                keyboardType: TextInputType.datetime,
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Localização'),
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Cor do cartaz'),
                onChanged: (v) => setModalState(() => dateColor = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty || dateController.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: Text(isEdit ? 'Guardar' : 'Criar'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final title = titleController.text.trim();
    final date = dateController.text.trim();
    if (title.isEmpty || date.isEmpty) return;

    setState(() => _loading = true);
    ApiResult<bool> res;
    if (isEdit) {
      res = await AdminService.instance.updateEvent(
        id: event.id,
        title: title,
        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
        date: date,
        location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
        imageUrl: event.imageUrl,
        dateColor: dateColor,
      );
    } else {
      res = await AdminService.instance.createEvent(
        title: title,
        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
        date: date,
        location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
        imageUrl: null,
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);
    if (res.ok) {
      if (isEdit) {
        await _loadEvents();
      } else {
        await _loadEvents();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Evento atualizado.' : 'Evento criado.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Erro')));
    }
  }

  Future<void> _deleteEvent(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Evento'),
        content: const Text('Tens a certeza que queres eliminar este evento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFC5C7D)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final res = await AdminService.instance.deleteEvent(id);
    if (!mounted) return;
    if (res.ok) {
      setState(() => _events.removeWhere((e) => e.id == id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento eliminado.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Erro')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isAdmin = auth.profile?.isMod ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administração'),
        bottom: isAdmin
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Painel'),
                  Tab(text: 'Utilizadores'),
                  Tab(text: 'Anúncios'),
                  Tab(text: 'Eventos'),
                ],
              )
            : null,
      ),
      body: !isAdmin
          ? const EmptyView(
              message: 'Acesso restrito a administradores.',
              icon: Icons.lock_outline,
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _dashboardView(),
                _usersView(),
                _announcementsView(),
                _eventsView(),
              ],
            ),
    );
  }

  Widget _dashboardView() {
    return _loading
        ? const LoadingView(message: 'A carregar painel...')
        : _error != null
            ? ErrorView(message: _error!, onRetry: _loadDashboard)
            : _dashboard == null
                ? const EmptyView(message: 'Sem dados.', icon: Icons.insights)
                : RefreshIndicator(
                    onRefresh: _loadDashboard,
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        Row(
                          children: [
                            _statCard('Publicações hoje', _dashboard!.postsToday, Icons.post_add),
                            const SizedBox(width: 10),
                            _statCard('Denúncias', _dashboard!.totalReports, Icons.flag),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _statCard('Últimas 24h', _dashboard!.reportsLast24h, Icons.schedule),
                            const SizedBox(width: 10),
                            _statCard('Anúncios ativos', _dashboard!.activeAnnouncements, Icons.campaign),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Denúncias pendentes (${_dashboard!.reports.length})',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        if (_dashboard!.reports.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: Text('Sem denúncias pendentes.')),
                          )
                        else
                          ..._dashboard!.reports.map((r) => _ReportCard(
                                report: r,
                                onDismiss: () => _processReport(r, 'dismiss'),
                                onDelete: () => _processReport(r, 'delete_post'),
                              )),
                        const SizedBox(height: 20),
                        Text(
                          'Atividade dos últimos 7 dias',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        _BarChart(
                          labels: _dashboard!.dailyLabels,
                          values: _dashboard!.dailyPosts,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
  }

  Widget _statCard(String label, int value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF7C5CFC).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF7C5CFC), size: 20),
            const SizedBox(height: 8),
            Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _usersView() {
    final auth = context.watch<AuthService>();
    final isSuper = auth.profile?.isSuperUser ?? false;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Pesquisar utilizador...',
                    isDense: true,
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _loadUsers(),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _roleFilter,
                hint: const Text('Todas'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Todas')),
                  DropdownMenuItem(value: 'member', child: Text('Membro')),
                  DropdownMenuItem(value: 'mod', child: Text('Mod')),
                  DropdownMenuItem(value: 'superuser', child: Text('Superuser')),
                ],
                onChanged: (v) {
                  setState(() {
                    _roleFilter = v == 'all' ? null : v;
                  });
                  _loadUsers();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _loadUsers)
                  : _users.isEmpty
                      ? const EmptyView(message: 'Sem utilizadores.', icon: Icons.people_outline)
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _users.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final u = _users[i];
                            final role = u.role ?? 'member';
                            final canManage = u.id != auth.profile?.id && isSuper;

                            return ListTile(
                              leading: AppAvatar(
                                url: u.avatarUrl,
                                initials: u.avatarInitials,
                                size: 42,
                                showOnline: true,
                                online: u.isOnline ?? false,
                              ),
                              title: Text(u.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                              subtitle: Text('@${u.username}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _RoleBadge(role: role),
                                  if (canManage) ...[
                                    PopupMenuButton<String>(
                                      tooltip: 'Ações',
                                      onSelected: (action) async {
                                        switch (action) {
                                          case 'promote':
                                            await _cycleRole(u.id, 'up');
                                          case 'demote':
                                            await _cycleRole(u.id, 'down');
                                          case 'ban':
                                            await _banUser(u.id, u.displayName);
                                          case 'delete':
                                            await _deleteUser(u.id, u.displayName);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        if (role != 'superuser')
                                          const PopupMenuItem(value: 'promote', child: Text('Promover')),
                                        if (role != 'member')
                                          const PopupMenuItem(value: 'demote', child: Text('Rebaixar')),
                                        const PopupMenuItem(value: 'ban', child: Text('Banir')),
                                        const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _announcementsView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _openAnnouncementModal(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Novo Anúncio'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _loadAnnouncements)
                  : _announcements.isEmpty
                      ? const EmptyView(message: 'Sem anúncios.', icon: Icons.campaign_outlined)
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _announcements.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final a = _announcements[i];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              title: Row(
                                children: [
                                  if (a.pinned) ...[
                                    const Icon(Icons.push_pin, size: 16, color: Color(0xFFFCB45C)),
                                    const SizedBox(width: 6),
                                  ],
                                  Expanded(
                                    child: Text(a.title,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '${a.status} · ${AppFormat.relativeTime(a.createdAt)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => _openAnnouncementModal(a),
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    tooltip: 'Editar',
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteAnnouncement(a.id),
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    color: const Color(0xFFFC5C7D),
                                    tooltip: 'Eliminar',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _eventsView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _openEventModal(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Novo Evento'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _loadEvents)
                  : _events.isEmpty
                      ? const EmptyView(message: 'Sem eventos.', icon: Icons.event_busy)
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _events.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final e = _events[i];
                            final dt = DateTime.tryParse(e.date);
                            final months = const ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              leading: Container(
                                width: 48,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: Color(int.parse((e.dateColor?.trim().isEmpty ?? true ? '#7C5CFC' : e.dateColor!.trim()).replaceFirst('#', '0xFF'))).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      dt != null ? '${dt.day}' : '-',
                                      style: TextStyle(
                                        color: Color(int.parse((e.dateColor?.trim().isEmpty ?? true ? '#7C5CFC' : e.dateColor!.trim()).replaceFirst('#', '0xFF'))),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      dt != null ? months[dt.month - 1] : '',
                                      style: TextStyle(
                                        color: Color(int.parse((e.dateColor?.trim().isEmpty ?? true ? '#7C5CFC' : e.dateColor!.trim()).replaceFirst('#', '0xFF'))),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(e.title,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                              subtitle: Text(
                                '${e.location ?? 'Sem local'} · ${AppFormat.relativeTime(e.createdAt)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => _openEventModal(e),
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    tooltip: 'Editar',
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteEvent(e.id),
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    color: const Color(0xFFFC5C7D),
                                    tooltip: 'Eliminar',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      'superuser' => ('Superuser', const Color(0xFFFC5C7D)),
      'mod' => ('Mod', const Color(0xFF5CB7FF)),
      _ => ('Membro', const Color(0xFF5CFCB4)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).brightness == Brightness.dark ? color : color.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final AdminReport report;
  final VoidCallback onDismiss;
  final VoidCallback onDelete;
  const _ReportCard({required this.report, required this.onDismiss, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, size: 16, color: Color(0xFFFC5C7D)),
                const SizedBox(width: 6),
                Text(report.reason ?? 'Denúncia',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                const Spacer(),
                Text(
                  AppFormat.relativeTime(report.createdAt),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            if (report.description != null && report.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(report.description!, style: const TextStyle(fontSize: 13)),
            ],
            if (report.postContent != null && report.postContent!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.postContent!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'por ${report.reporter?.displayName ?? '@${report.reporter?.username ?? '?'}'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onDismiss,
                  child: const Text('Ignorar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFC5C7D)),
                  onPressed: onDelete,
                  child: const Text('Eliminar post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<String> labels;
  final List<int> values;
  const _BarChart({required this.labels, required this.values});

  @override
  Widget build(BuildContext context) {
    final max = values.fold<int>(0, (m, v) => v > m ? v : m);
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF7C5CFC).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final h = max == 0 ? 0.0 : values[i] / max;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(),
                  Container(
                    height: (h * 80).clamp(2, 80),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C5CFC),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels.length > i ? labels[i] : '',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
