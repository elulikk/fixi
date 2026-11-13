import 'package:dio/dio.dart';

import '../models/models.dart';

class ApiException implements Exception {
  final String code, message;
  final int? status;
  const ApiException(this.code, this.message, [this.status]);
  bool get isNetwork => code == 'NETWORK';
  @override
  String toString() => message;
}

String errorText(Object e) => e is ApiException ? e.message : 'Algo salió mal. Probá de nuevo.';

class ListingsQuery {
  final double lat, lng, radiusKm;
  final String? categoryId, q;
  final String sort;
  const ListingsQuery({required this.lat, required this.lng, this.radiusKm = 20, this.categoryId, this.q, this.sort = 'best'});
  @override
  bool operator ==(Object other) =>
      other is ListingsQuery &&
      other.lat.toStringAsFixed(3) == lat.toStringAsFixed(3) &&
      other.lng.toStringAsFixed(3) == lng.toStringAsFixed(3) &&
      other.radiusKm == radiusKm &&
      other.categoryId == categoryId &&
      other.q == q &&
      other.sort == sort;
  @override
  int get hashCode => Object.hash(lat.toStringAsFixed(3), lng.toStringAsFixed(3), radiusKm, categoryId, q, sort);
}

class ApiClient {
  ApiClient({required this.baseUrl, required this.token, this.onUnauthorized}) {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 25),
      sendTimeout: const Duration(seconds: 30),
    ));
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      o.baseUrl = '${baseUrl().replaceAll(RegExp(r'/+$'), '')}/api/v1';
      final t = token();
      if (t != null && t.isNotEmpty) o.headers['Authorization'] = 'Bearer $t';
      h.next(o);
    }));
  }

  final String Function() baseUrl;
  final String? Function() token;
  final void Function()? onUnauthorized;
  late final Dio _dio;

  /// Convierte una URL relativa (ej: /uploads/x.jpg) en absoluta.
  String abs(String url) => url.startsWith('http') ? url : '${baseUrl().replaceAll(RegExp(r'/+$'), '')}${url.startsWith('/') ? '' : '/'}$url';

  static ApiException mapError(Object e) {
    if (e is ApiException) return e;
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] is Map) {
        final err = data['error'] as Map;
        return ApiException('${err['code'] ?? 'ERROR'}', '${err['message'] ?? 'Ocurrió un error.'}', e.response?.statusCode);
      }
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const ApiException('NETWORK', 'El servidor tardó demasiado en responder. Revisá tu conexión e intentá de nuevo.');
        case DioExceptionType.connectionError:
          return const ApiException('NETWORK', 'No pudimos conectar con el servidor. Revisá tu conexión o la URL del servidor en Ajustes.');
        default:
          break;
      }
      final s = e.response?.statusCode;
      if (s != null) return ApiException('HTTP_$s', s >= 500 ? 'El servidor tuvo un problema. Probá en un rato.' : 'No se pudo completar la acción.', s);
      return const ApiException('NETWORK', 'No pudimos conectar con el servidor.');
    }
    return ApiException('UNKNOWN', 'Algo salió mal. Probá de nuevo.');
  }

  Future<Map<String, dynamic>> _req(String method, String path, {Map<String, dynamic>? query, Object? body}) async {
    try {
      final r = await _dio.request<dynamic>(path,
          queryParameters: query?..removeWhere((k, v) => v == null), data: body, options: Options(method: method));
      return asMap(r.data);
    } catch (e) {
      final ex = mapError(e);
      if (ex.status == 401 && !path.startsWith('/auth/')) onUnauthorized?.call();
      throw ex;
    }
  }

  Future<Map<String, dynamic>> _get(String p, {Map<String, dynamic>? q}) => _req('GET', p, query: q);
  Future<Map<String, dynamic>> _post(String p, [Object? b]) => _req('POST', p, body: b ?? {});

  /// Prueba `/health` en una URL base arbitraria.
  static Future<bool> health(String base) async {
    try {
      final d = Dio(BaseOptions(connectTimeout: const Duration(seconds: 6), receiveTimeout: const Duration(seconds: 6)));
      final r = await d.get<dynamic>('${base.replaceAll(RegExp(r'/+$'), '')}/health');
      return r.data is Map && r.data['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  // ---- auth / perfil
  Future<(String, AppUser)> login(String email, String password) async {
    final j = await _post('/auth/login', {'email': email, 'password': password});
    return ('${j['token']}', AppUser.fromJson(asMap(j['user'])));
  }

  Future<(String, AppUser)> register(String name, String email, String password, String? phone) async {
    final j = await _post('/auth/register', {'name': name, 'email': email, 'password': password, if (phone != null && phone.isNotEmpty) 'phone': phone});
    return ('${j['token']}', AppUser.fromJson(asMap(j['user'])));
  }

  Future<(AppUser, TechProfile?)> me() async {
    final j = await _get('/me');
    return (AppUser.fromJson(asMap(j['user'] ?? j)), j['techProfile'] is Map ? TechProfile.fromJson(asMap(j['techProfile'])) : null);
  }

  Future<void> patchMe(Map<String, dynamic> body) => _req('PATCH', '/me', body: body);
  Future<void> putTechProfile(Map<String, dynamic> body) => _req('PUT', '/me/tech-profile', body: body);
  Future<TechPublic> techPublic(String id) async => TechPublic.fromJson(await _get('/techs/$id'));

  // ---- catálogo
  Future<List<Category>> categories() async => asList((await _get('/categories'))['items']).map(Category.fromJson).toList();

  // ---- necesidades y ofertas
  Future<NeedRequest> createRequest(Map<String, dynamic> body) async {
    final j = await _post('/requests', body);
    return NeedRequest.fromJson(asMap(j['request'] ?? j));
  }

  Future<List<NeedRequest>> myRequests() async => asList((await _get('/requests/mine'))['items']).map(NeedRequest.fromJson).toList();
  Future<RequestDetail> requestDetail(String id, [String sort = 'best']) async => RequestDetail.fromJson(await _get('/requests/$id', q: {'sort': sort}));
  Future<void> cancelRequest(String id) => _post('/requests/$id/cancel');
  Future<List<NeedRequest>> nearby(double lat, double lng, double radiusKm, [String? categoryId]) async =>
      asList((await _get('/requests/nearby', q: {'lat': lat, 'lng': lng, 'radiusKm': radiusKm, 'categoryId': categoryId}))['items']).map(NeedRequest.fromJson).toList();
  Future<void> sendOffer(String requestId, Map<String, dynamic> body) => _post('/requests/$requestId/offers', body);
  Future<List<Offer>> myOffers() async => asList((await _get('/offers/mine'))['items']).map(Offer.fromJson).toList();
  Future<void> withdrawOffer(String id) => _post('/offers/$id/withdraw');
  Future<Job> acceptOffer(String id) async => Job.fromJson(await _post('/offers/$id/accept'));

  // ---- servicios
  Future<List<Listing>> listings(ListingsQuery q) async => asList((await _get('/listings', q: {
        'lat': q.lat,
        'lng': q.lng,
        'radiusKm': q.radiusKm,
        'categoryId': q.categoryId,
        'q': (q.q ?? '').isEmpty ? null : q.q,
        'sort': q.sort,
      }))['items'])
          .map((e) => Listing.fromJson(e))
          .toList();
  Future<List<Listing>> myListings() async => asList((await _get('/listings/mine'))['items']).map((e) => Listing.fromJson(e)).toList();
  Future<void> createListing(Map<String, dynamic> b) => _post('/listings', b);
  Future<void> updateListing(String id, Map<String, dynamic> b) => _req('PATCH', '/listings/$id', body: b);
  Future<void> deleteListing(String id) => _req('DELETE', '/listings/$id');
  Future<Job> book(String listingId, Map<String, dynamic> b) async => Job.fromJson(await _post('/listings/$listingId/book', b));

  // ---- trabajos
  Future<List<Job>> jobs(String role, [String? status]) async => asList((await _get('/jobs', q: {'role': role, 'status': status}))['items']).map(Job.fromJson).toList();
  Future<Job> job(String id) async => Job.fromJson(await _get('/jobs/$id'));
  Future<void> setStatus(String id, String status) => _post('/jobs/$id/status', {'status': status});
  Future<List<ChatMessage>> messages(String id) async => asList((await _get('/jobs/$id/messages'))['items']).map(ChatMessage.fromJson).toList();
  Future<ChatMessage> sendMessage(String id, String text) async {
    final j = await _post('/jobs/$id/messages', {'text': text});
    return ChatMessage.fromJson(asMap(j['message'] ?? j));
  }

  Future<void> review(String id, int rating, String comment) => _post('/jobs/$id/review', {'rating': rating, 'comment': comment});
  Future<void> sendLocation(String id, double lat, double lng) => _post('/jobs/$id/location', {'lat': lat, 'lng': lng});

  // ---- pagos
  Future<(Payment?, String?)> pay(String jobId) async {
    final j = await _post('/jobs/$jobId/pay');
    final p = j['payment'] is Map ? Payment.fromJson(asMap(j['payment'])) : null;
    return (p, (j['checkoutUrl'] ?? p?.checkoutUrl) as String?);
  }

  Future<Payment> payment(String id) async => Payment.fromJson(asMap((await _get('/payments/$id'))['payment']));
  Future<Earnings> earnings() async => Earnings.fromJson(await _get('/me/earnings'));
  Future<String?> connectUrl() async => (await _get('/payments/connect/url'))['url'] as String?;

  // ---- notificaciones
  Future<List<AppNotification>> notifications() async => asList((await _get('/notifications'))['items']).map(AppNotification.fromJson).toList();
  Future<void> readAll() => _post('/notifications/read-all');

  // ---- archivos
  Future<String> upload(String path) async {
    try {
      final form = FormData.fromMap({'file': await MultipartFile.fromFile(path, filename: path.split(RegExp(r'[\\/]')).last)});
      final r = await _dio.post<dynamic>('/uploads', data: form);
      return abs('${asMap(r.data)['url']}');
    } catch (e) {
      throw mapError(e);
    }
  }
}
