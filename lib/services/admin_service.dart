import '../core/api_client.dart';
import '../models/api_response.dart';
import '../models/announcement.dart';
import '../models/author.dart';
import '../models/event.dart';

class AdminReport {
  final String id;
  final String postId;
  final String? reason;
  final String? description;
  final String status;
  final String? createdAt;
  final Author? reporter;
  final String? postContent;
  final Author? postAuthor;

  AdminReport({
    required this.id,
    required this.postId,
    this.reason,
    this.description,
    this.status = 'pending',
    this.createdAt,
    this.reporter,
    this.postContent,
    this.postAuthor,
  });

  factory AdminReport.fromJson(Map<String, dynamic> json) {
    Author? reporter;
    if (json['reporter'] is Map) {
      reporter = Author.fromJson((json['reporter'] as Map).cast<String, dynamic>());
    }
    Author? postAuthor;
    final post = json['post'];
    if (post is Map && post['author'] is Map) {
      postAuthor = Author.fromJson((post['author'] as Map).cast<String, dynamic>());
    }
    return AdminReport(
      id: json['id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? '',
      reason: json['reason']?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at']?.toString(),
      reporter: reporter,
      postContent: post is Map ? post['content']?.toString() : null,
      postAuthor: postAuthor,
    );
  }
}

class AdminDashboard {
  final List<AdminReport> reports;
  final int totalReports;
  final int reportsLast24h;
  final List<Announcement> announcements;
  final int totalAnnouncements;
  final int postsToday;
  final List<int> dailyPosts;
  final List<String> dailyLabels;
  final int activeAnnouncements;

  AdminDashboard({
    required this.reports,
    required this.totalReports,
    required this.reportsLast24h,
    required this.announcements,
    required this.totalAnnouncements,
    required this.postsToday,
    required this.dailyPosts,
    required this.dailyLabels,
    required this.activeAnnouncements,
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    List<AdminReport> reports = [];
    if (json['reports'] is List) {
      reports = (json['reports'] as List)
          .whereType<Map>()
          .map((e) => AdminReport.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    List<Announcement> announcements = [];
    if (json['announcements'] is List) {
      announcements = (json['announcements'] as List)
          .whereType<Map>()
          .map((e) => Announcement.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    List<int> dailyPosts = (json['dailyPosts'] as List? ?? [])
        .map((e) => (e as num?)?.toInt() ?? 0)
        .toList();
    List<String> dailyLabels = (json['dailyLabels'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    return AdminDashboard(
      reports: reports,
      totalReports: (json['totalReports'] as num?)?.toInt() ?? 0,
      reportsLast24h: (json['reportsLast24h'] as num?)?.toInt() ?? 0,
      announcements: announcements,
      totalAnnouncements: (json['totalAnnouncements'] as num?)?.toInt() ?? 0,
      postsToday: (json['postsToday'] as num?)?.toInt() ?? 0,
      dailyPosts: dailyPosts,
      dailyLabels: dailyLabels,
      activeAnnouncements: (json['activeAnnouncements'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminUsersPage {
  final List<Author> users;
  final int total;

  AdminUsersPage({required this.users, required this.total});

  factory AdminUsersPage.fromJson(Map<String, dynamic> json) {
    List<Author> users = [];
    if (json['users'] is List) {
      users = (json['users'] as List)
          .whereType<Map>()
          .map((e) => Author.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    return AdminUsersPage(users: users, total: (json['total'] as num?)?.toInt() ?? 0);
  }
}

class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();
  final ApiClient _api = ApiClient.instance;

  Future<ApiResult<AdminDashboard>> getDashboard() async {
    try {
      final res = await _api.get('/api/admin/dashboard');
      return ApiParser.parse(res, (json) => AdminDashboard.fromJson(json as Map<String, dynamic>));
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar painel.');
    }
  }

  Future<ApiResult<AdminUsersPage>> getUsers({String? role, String? search}) async {
    try {
      final params = <String, String>{};
      if (role != null && role.isNotEmpty && role != 'all') params['role'] = role;
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _api.get('/api/admin/users', query: params.isEmpty ? null : params);
      return ApiParser.parse(res, (json) => AdminUsersPage.fromJson(json as Map<String, dynamic>));
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar utilizadores.');
    }
  }

  Future<ApiResult<bool>> processReport(String reportId, String action) async {
    try {
      final res = await _api.patch(
        '/api/admin/reports',
        body: {'report_id': reportId, 'action': action},
      );
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao processar denúncia.'),
          statusCode: res.statusCode,
        );
      }
      return const ApiResult(data: true);
    } catch (_) {
      return const ApiResult(error: 'Erro ao processar denúncia.');
    }
  }

  Future<ApiResult<Announcement>> createAnnouncement({
    required String title,
    String? content,
    String status = 'draft',
    bool pinned = false,
  }) async {
    try {
      final res = await _api.post(
        '/api/announcements/admin',
        body: {'title': title, 'content': content, 'status': status, 'pinned': pinned},
      );
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao criar anúncio.'),
          statusCode: res.statusCode,
        );
      }
      return ApiParser.parse(res, (json) => Announcement.fromJson(json as Map<String, dynamic>));
    } catch (_) {
      return const ApiResult(error: 'Erro ao criar anúncio.');
    }
  }

  Future<ApiResult<Announcement>> updateAnnouncement({
    required String id,
    required String title,
    String? content,
    String status = 'draft',
    bool pinned = false,
  }) async {
    try {
      final res = await ApiClient.instance.patch(
        '/api/announcements/admin',
        body: {'id': id, 'title': title, 'content': content, 'status': status, 'pinned': pinned},
      );
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao atualizar anúncio.'),
          statusCode: res.statusCode,
        );
      }
      return ApiParser.parse(res, (json) => Announcement.fromJson(json as Map<String, dynamic>));
    } catch (_) {
      return const ApiResult(error: 'Erro ao atualizar anúncio.');
    }
  }

  Future<ApiResult<bool>> deleteAnnouncement(String id) async {
    try {
      final res = await ApiClient.instance.delete('/api/announcements/admin?id=$id');
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao eliminar anúncio.'),
          statusCode: res.statusCode,
        );
      }
      return const ApiResult(data: true);
    } catch (_) {
      return const ApiResult(error: 'Erro ao eliminar anúncio.');
    }
  }

  Future<ApiResult<bool>> createEvent({
    required String title,
    String? description,
    required String date,
    String? location,
    String? imageUrl,
  }) async {
    try {
      final res = await ApiClient.instance.post(
        '/api/events/admin',
        body: {
          'title': title,
          'description': description,
          'date': date,
          'location': location,
          'image_url': imageUrl,
        },
      );
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao criar evento.'),
          statusCode: res.statusCode,
        );
      }
      return const ApiResult(data: true);
    } catch (_) {
      return const ApiResult(error: 'Erro ao criar evento.');
    }
  }

  Future<ApiResult<bool>> updateEvent({
    required String id,
    required String title,
    String? description,
    required String date,
    String? location,
    String? imageUrl,
    String? dateColor,
  }) async {
    try {
      final res = await ApiClient.instance.put(
        '/api/events/admin',
        body: {
          'id': id,
          'title': title,
          'description': description,
          'date': date,
          'location': location,
          'image_url': imageUrl,
          'date_color': dateColor,
        },
      );
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao atualizar evento.'),
          statusCode: res.statusCode,
        );
      }
      return const ApiResult(data: true);
    } catch (_) {
      return const ApiResult(error: 'Erro ao atualizar evento.');
    }
  }

  Future<ApiResult<bool>> deleteEvent(String id) async {
    try {
      final res = await ApiClient.instance.delete('/api/events/admin?id=$id');
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao eliminar evento.'),
          statusCode: res.statusCode,
        );
      }
      return const ApiResult(data: true);
    } catch (_) {
      return const ApiResult(error: 'Erro ao eliminar evento.');
    }
  }

  Future<ApiResult<List<Announcement>>> getAnnouncements() async {
    try {
      final res = await _api.get('/api/admin/dashboard');
      return ApiParser.parse(res, (json) {
        final dashboard = json as Map<String, dynamic>;
        final list = (dashboard['announcements'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        return list.map((e) => Announcement.fromJson(e)).toList();
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar anúncios.');
    }
  }

  Future<ApiResult<List<Event>>> getAdminEvents() async {
    try {
      final res = await _api.get('/api/events');
      return ApiParser.parse(res, (json) {
        final list = (json as List).whereType<Map<String, dynamic>>().toList();
        return list.map((e) => Event.fromJson(e)).toList();
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar eventos.');
    }
  }

  Future<ApiResult<bool>> banUser(String userId, {String? reason, int? durationDays}) async {
    try {
      final res = await ApiClient.instance.post(
        '/api/admin/users/$userId/ban',
        body: {
          'user_id': userId,
          'reason': reason,
          'duration_days': durationDays,
        },
      );
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao banir utilizador.'),
          statusCode: res.statusCode,
        );
      }
      return const ApiResult(data: true);
    } catch (_) {
      return const ApiResult(error: 'Erro ao banir utilizador.');
    }
  }

  Future<ApiResult<bool>> deleteUser(String userId) async {
    try {
      final res = await ApiClient.instance.delete('/api/admin/users/$userId/delete');
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao eliminar utilizador.'),
          statusCode: res.statusCode,
        );
      }
      return const ApiResult(data: true);
    } catch (_) {
      return const ApiResult(error: 'Erro ao eliminar utilizador.');
    }
  }

  Future<ApiResult<bool>> updateUserRole(String userId, String role) async {
    try {
      final res = await ApiClient.instance.patch(
        '/api/admin/users/$userId/role',
        body: {'role': role},
      );
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao atualizar role.'),
          statusCode: res.statusCode,
        );
      }
      return const ApiResult(data: true);
    } catch (_) {
      return const ApiResult(error: 'Erro ao atualizar role.');
    }
  }
}
