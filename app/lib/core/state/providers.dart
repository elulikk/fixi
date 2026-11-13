import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/realtime.dart';
import '../config/constants.dart';
import '../models/models.dart';

// ---------------------------------------------------------------- base
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('prefs no inicializadas'));

class AppSettings {
  final String baseUrl;
  final ThemeMode theme;
  final String mode; // client | tech
  final bool onboarded;
  const AppSettings({required this.baseUrl, required this.theme, required this.mode, required this.onboarded});
  bool get techMode => mode == 'tech';
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this.p)
      : super(AppSettings(
          baseUrl: p.getString('baseUrl') ?? AppConst.defaultBaseUrl,
          theme: ThemeMode.values.firstWhere((m) => m.name == p.getString('theme'), orElse: () => ThemeMode.system),
          mode: p.getString('mode') ?? 'client',
          onboarded: p.getBool('onboarded') ?? false,
        ));
  final SharedPreferences p;

  AppSettings _copy({String? baseUrl, ThemeMode? theme, String? mode, bool? onboarded}) => AppSettings(
        baseUrl: baseUrl ?? state.baseUrl,
        theme: theme ?? state.theme,
        mode: mode ?? state.mode,
        onboarded: onboarded ?? state.onboarded,
      );

  void setBaseUrl(String v) {
    var u = v.trim();
    if (u.isEmpty) u = AppConst.defaultBaseUrl;
    if (!u.startsWith('http')) u = 'http://$u';
    u = u.replaceAll(RegExp(r'/+$'), '');
    p.setString('baseUrl', u);
    state = _copy(baseUrl: u);
  }

  void setTheme(ThemeMode m) {
    p.setString('theme', m.name);
    state = _copy(theme: m);
  }

  void setMode(String m) {
    p.setString('mode', m);
    state = _copy(mode: m);
  }

  void setOnboarded() {
    p.setBool('onboarded', true);
    state = _copy(onboarded: true);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) => SettingsNotifier(ref.watch(prefsProvider)));

final apiProvider = Provider<ApiClient>((ref) {
  final p = ref.watch(prefsProvider);
  return ApiClient(
    baseUrl: () => p.getString('baseUrl') ?? AppConst.defaultBaseUrl,
    token: () => p.getString('token'),
    onUnauthorized: () => ref.read(authProvider.notifier).sessionExpired(),
  );
});

final realtimeProvider = Provider<RealtimeService>((ref) {
  final p = ref.watch(prefsProvider);
  final s = RealtimeService(baseUrl: () => p.getString('baseUrl') ?? AppConst.defaultBaseUrl, token: () => p.getString('token'));
  ref.onDispose(s.dispose);
  return s;
});

final wsEventsProvider = StreamProvider<WsEvent>((ref) => ref.watch(realtimeProvider).events);

// ---------------------------------------------------------------- auth
enum AuthStatus { unknown, out, authed }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final TechProfile? tech;
  const AuthState(this.status, {this.user, this.tech});
}

/// Al volver a la app (p. ej. desde el navegador tras vincular Mercado Pago) refresca el perfil.
class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver(this.onResume);
  final void Function() onResume;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this.ref) : super(const AuthState(AuthStatus.unknown)) {
    _init();
    _obs = _ResumeObserver(() {
      if (state.status == AuthStatus.authed) refresh();
    });
    WidgetsBinding.instance.addObserver(_obs);
  }
  late final _ResumeObserver _obs;
  final Ref ref;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_obs);
    super.dispose();
  }
  SharedPreferences get _p => ref.read(prefsProvider);

  Future<void> _init() async {
    final t0 = DateTime.now();
    final token = _p.getString('token');
    AuthState next = const AuthState(AuthStatus.out);
    if (token != null) {
      try {
        final (u, t) = await ref.read(apiProvider).me();
        _cacheUser(u);
        next = AuthState(AuthStatus.authed, user: u, tech: t);
      } catch (e) {
        final cached = _p.getString('user');
        if (e is ApiException && e.status == 401) {
          await _p.remove('token');
        } else if (cached != null) {
          next = AuthState(AuthStatus.authed, user: AppUser.fromJson(asMap(jsonDecode(cached))));
        }
      }
    }
    final wait = 1500 - DateTime.now().difference(t0).inMilliseconds;
    if (wait > 0) await Future<void>.delayed(Duration(milliseconds: wait));
    if (!mounted) return;
    _apply(next);
  }

  void _cacheUser(AppUser u) => _p.setString('user', jsonEncode(u.toJson()));

  void _apply(AuthState s) {
    final settings = ref.read(settingsProvider.notifier);
    if (s.status == AuthStatus.authed) {
      if (!(s.user?.isTechnician ?? false) && ref.read(settingsProvider).techMode) settings.setMode('client');
      ref.read(realtimeProvider).start();
    } else {
      ref.read(realtimeProvider).stop();
    }
    state = s;
  }

  Future<void> _afterAuth(String token, AppUser u) async {
    await _p.setString('token', token);
    _cacheUser(u);
    ref.invalidate(notificationsProvider);
    ref.invalidate(locationProvider);
    TechProfile? t;
    AppUser user = u;
    try {
      final r = await ref.read(apiProvider).me();
      user = r.$1;
      t = r.$2;
      _cacheUser(user);
    } catch (_) {}
    ref.read(realtimeProvider).restart();
    state = AuthState(AuthStatus.authed, user: user, tech: t);
  }

  Future<void> login(String email, String password, {bool asTech = false}) async {
    final (token, user) = await ref.read(apiProvider).login(email.trim(), password);
    await _afterAuth(token, user);
    final canTech = state.user?.isTechnician ?? false;
    ref.read(settingsProvider.notifier).setMode(asTech && canTech ? 'tech' : 'client');
  }

  Future<void> register(String name, String email, String password, String? phone) async {
    final (token, user) = await ref.read(apiProvider).register(name.trim(), email.trim(), password, phone?.trim());
    await _afterAuth(token, user);
    ref.read(settingsProvider.notifier).setMode('client');
  }

  Future<void> refresh() async {
    try {
      final (u, t) = await ref.read(apiProvider).me();
      _cacheUser(u);
      if (mounted) state = AuthState(AuthStatus.authed, user: u, tech: t);
    } catch (_) {}
  }

  void setTech(TechProfile t) {
    if (state.user != null) state = AuthState(AuthStatus.authed, user: state.user, tech: t);
  }

  Future<void> logout() async {
    await _p.remove('token');
    await _p.remove('user');
    ref.read(realtimeProvider).stop();
    ref.invalidate(notificationsProvider);
    ref.invalidate(locationProvider);
    ref.read(settingsProvider.notifier).setMode('client');
    state = const AuthState(AuthStatus.out);
  }

  void sessionExpired() {
    if (state.status == AuthStatus.authed) {
      logout();
      showSessionExpired?.call();
    }
  }

  void Function()? showSessionExpired;
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref));

// ---------------------------------------------------------------- ubicación
class GeoPoint {
  final LatLng ll;
  final bool isDefault;
  final String label;
  const GeoPoint(this.ll, this.isDefault, this.label);
}

Future<Position?> currentPosition() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 8));
    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  } catch (_) {
    return null;
  }
}

final locationProvider = FutureProvider<GeoPoint>((ref) async {
  final user = ref.read(authProvider).user;
  final saved = (user?.lat != null && user?.lng != null) ? LatLng(user!.lat!, user.lng!) : null;
  final pos = await currentPosition();
  if (pos != null) {
    final gps = LatLng(pos.latitude, pos.longitude);
    // Si el GPS cae a más de 200 km de la zona de servicio (p. ej. emulador en California),
    // usamos la dirección guardada o el Obelisco.
    final ref0 = saved ?? AppConst.obelisco;
    final far = const Distance().as(LengthUnit.Kilometer, gps, ref0) > 200;
    if (!far) return GeoPoint(gps, false, (user?.address?.isNotEmpty ?? false) ? user!.address! : 'Tu ubicación actual');
  }
  if (saved != null) return GeoPoint(saved, false, user?.address ?? 'Tu dirección guardada');
  return const GeoPoint(AppConst.obelisco, true, 'Obelisco, CABA (ubicación por defecto)');
});

// ---------------------------------------------------------------- datos
final categoriesProvider = FutureProvider<List<Category>>((ref) => ref.watch(apiProvider).categories());

final listingsProvider = FutureProvider.autoDispose.family<List<Listing>, ListingsQuery>((ref, q) => ref.watch(apiProvider).listings(q));
final myRequestsProvider = FutureProvider.autoDispose<List<NeedRequest>>((ref) => ref.watch(apiProvider).myRequests());
final requestDetailProvider = FutureProvider.autoDispose.family<RequestDetail, String>((ref, id) => ref.watch(apiProvider).requestDetail(id));
final jobsProvider = FutureProvider.autoDispose.family<List<Job>, String>((ref, role) => ref.watch(apiProvider).jobs(role));
final jobProvider = FutureProvider.autoDispose.family<Job, String>((ref, id) => ref.watch(apiProvider).job(id));
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) => ref.watch(apiProvider).notifications());
final techPublicProvider = FutureProvider.autoDispose.family<TechPublic, String>((ref, id) => ref.watch(apiProvider).techPublic(id));
final myOffersProvider = FutureProvider.autoDispose<List<Offer>>((ref) => ref.watch(apiProvider).myOffers());
final myListingsProvider = FutureProvider.autoDispose<List<Listing>>((ref) => ref.watch(apiProvider).myListings());
final earningsProvider = FutureProvider.autoDispose<Earnings>((ref) => ref.watch(apiProvider).earnings());

class NearbyQuery {
  final double lat, lng, radiusKm;
  final String? categoryId;
  const NearbyQuery(this.lat, this.lng, this.radiusKm, this.categoryId);
  @override
  bool operator ==(Object other) => other is NearbyQuery && other.lat == lat && other.lng == lng && other.radiusKm == radiusKm && other.categoryId == categoryId;
  @override
  int get hashCode => Object.hash(lat, lng, radiusKm, categoryId);
}

final nearbyProvider = FutureProvider.autoDispose.family<List<NeedRequest>, NearbyQuery>(
    (ref, q) => ref.watch(apiProvider).nearby(q.lat, q.lng, q.radiusKm, q.categoryId));

// ---------------------------------------------------------------- estado de UI compartido
final clientTabProvider = StateProvider<int>((ref) => 0);
final techTabProvider = StateProvider<int>((ref) => 0);
final exploreCategoryProvider = StateProvider<String?>((ref) => null);
final exploreQueryProvider = StateProvider<String>((ref) => '');
final activeChatProvider = StateProvider<String?>((ref) => null);
final liveLocationProvider = StateProvider.family<LatLng?, String>((ref, jobId) => null);

/// Envía la ubicación del técnico mientras tiene trabajos `on_the_way`.
class LocationSender {
  LocationSender(this.ref);
  final Ref ref;
  Timer? _timer;
  final Set<String> _ids = {};

  void sync(List<Job> jobs) {
    _ids
      ..clear()
      ..addAll(jobs.where((j) => j.status == 'on_the_way').map((j) => j.id));
    if (_ids.isEmpty) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(const Duration(seconds: 15), (_) => _tick());
      _tick();
    }
  }

  Future<void> _tick() async {
    if (_ids.isEmpty) return;
    final pos = await currentPosition();
    if (pos == null) return;
    for (final id in _ids.toList()) {
      try {
        await ref.read(apiProvider).sendLocation(id, pos.latitude, pos.longitude);
      } catch (_) {}
    }
  }

  void dispose() => _timer?.cancel();
}

final locationSenderProvider = Provider<LocationSender>((ref) {
  final s = LocationSender(ref);
  ref.onDispose(s.dispose);
  return s;
});
