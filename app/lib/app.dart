import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'core/api/realtime.dart';
import 'core/models/models.dart';
import 'core/state/providers.dart';
import 'core/theme/app_theme.dart';
import 'core/util/format.dart';
import 'core/widgets/common.dart';
import 'features/auth/auth_screens.dart';
import 'features/client/client_screens.dart';
import 'features/client/request_flow.dart';
import 'features/jobs/job_screens.dart';
import 'features/onboarding/onboarding_screens.dart';
import 'features/profile/profile_screens.dart';
import 'features/shared/shell.dart';
import 'features/tech/tech_screens.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider.select((s) => s.status), (_, __) => refresh.value++);
  ref.listen(settingsProvider.select((s) => s.onboarded), (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  String? redirect(BuildContext c, GoRouterState st) {
    final status = ref.read(authProvider).status;
    final onboarded = ref.read(settingsProvider).onboarded;
    final loc = st.matchedLocation;
    const publicRoutes = ['/onboarding', '/login', '/register', '/server'];
    if (status == AuthStatus.unknown) return loc == '/splash' ? null : '/splash';
    if (status == AuthStatus.out) {
      if (loc == '/splash') return onboarded ? '/login' : '/onboarding';
      if (!publicRoutes.contains(loc)) return onboarded ? '/login' : '/onboarding';
      return null;
    }
    if (loc == '/splash' || loc == '/login' || loc == '/register' || loc == '/onboarding') return '/home';
    return null;
  }

  CustomTransitionPage<void> fade(GoRouterState s, Widget child) => CustomTransitionPage<void>(
      key: s.pageKey, child: child, transitionsBuilder: (c, a, sa, w) => FadeTransition(opacity: a, child: w));

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: redirect,
    routes: [
      GoRoute(path: '/splash', pageBuilder: (c, s) => fade(s, const SplashScreen())),
      GoRoute(path: '/onboarding', pageBuilder: (c, s) => fade(s, const OnboardingScreen())),
      GoRoute(path: '/login', pageBuilder: (c, s) => fade(s, const LoginScreen())),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/server', builder: (c, s) => const ServerScreen()),
      GoRoute(path: '/home', pageBuilder: (c, s) => fade(s, const HomeShell())),
      GoRoute(path: '/need/new', builder: (c, s) => const RequestFlowScreen()),
      GoRoute(path: '/need/:id', builder: (c, s) => RequestDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/t/:id', builder: (c, s) => TechPublicScreen(id: s.pathParameters['id']!, heroSeed: s.extra as String?)),
      GoRoute(path: '/listing', builder: (c, s) => ListingDetailScreen(listing: s.extra as Listing)),
      GoRoute(path: '/job/:id', builder: (c, s) => JobScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/job/:id/pay', builder: (c, s) => PayScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/job/:id/chat', builder: (c, s) => ChatScreen(jobId: s.pathParameters['id']!, title: s.extra as String?)),
      GoRoute(path: '/notifications', builder: (c, s) => const NotificationsScreen()),
      GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
      GoRoute(path: '/profile/edit', builder: (c, s) => const EditProfileScreen()),
      GoRoute(path: '/help', builder: (c, s) => const HelpScreen()),
      GoRoute(path: '/tech-setup', builder: (c, s) => const TechSetupScreen()),
      GoRoute(path: '/my-offers', builder: (c, s) => const MyOffersScreen()),
      GoRoute(path: '/my-listings', builder: (c, s) => const MyListingsScreen()),
      GoRoute(path: '/listing-edit', builder: (c, s) => ListingEditScreen(listing: s.extra as Listing?)),
      GoRoute(path: '/opportunity/:id', builder: (c, s) => OpportunityScreen(id: s.pathParameters['id']!, initial: s.extra as NeedRequest?)),
    ],
  );
});

class FixiApp extends ConsumerWidget {
  const FixiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final theme = ref.watch(settingsProvider.select((s) => s.theme));

    ref.listen<AsyncValue<WsEvent>>(wsEventsProvider, (_, next) {
      final ev = next.valueOrNull;
      if (ev != null) _onEvent(ref, ev);
    });

    return MaterialApp.router(
      title: 'Fixi',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      routerConfig: router,
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: dark ? FixiColors.cardDark : Colors.white,
            systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      themeMode: theme,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: const Locale('es', 'AR'),
      supportedLocales: const [Locale('es', 'AR'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }

  void _onEvent(WidgetRef ref, WsEvent ev) {
    final d = ev.data;
    final jobId = '${d['jobId'] ?? d['id'] ?? ''}';
    switch (ev.type) {
      case 'offer.new':
        ref.invalidate(requestDetailProvider);
        ref.invalidate(myRequestsProvider);
        final o = asMap(d['offer'] ?? d);
        final price = o['price'];
        showSnack(null, price != null ? 'Llegó una oferta nueva por ${money(price as num)}' : 'Llegó una oferta nueva', ok: true);
        break;
      case 'offer.accepted':
        ref.invalidate(myOffersProvider);
        ref.invalidate(jobsProvider);
        showSnack(null, '¡Aceptaron tu oferta! Revisá tus trabajos.', ok: true);
        break;
      case 'offer.rejected':
        ref.invalidate(myOffersProvider);
        break;
      case 'request.new':
        ref.invalidate(nearbyProvider);
        showSnack(null, 'Hay una necesidad nueva cerca tuyo');
        break;
      case 'job.updated':
        ref.invalidate(jobsProvider);
        ref.invalidate(jobProvider);
        ref.invalidate(earningsProvider);
        ref.invalidate(myRequestsProvider);
        break;
      case 'message.new':
        final m = asMap(d['message'] ?? d);
        if (ref.read(activeChatProvider) != '${m['jobId']}') showSnack(null, 'Mensaje nuevo: ${m['text'] ?? ''}');
        break;
      case 'tech.location':
        final lat = (d['lat'] as num?)?.toDouble();
        final lng = (d['lng'] as num?)?.toDouble();
        if (lat != null && lng != null && jobId.isNotEmpty) {
          ref.read(liveLocationProvider('${d['jobId']}').notifier).state = LatLng(lat, lng);
        }
        break;
      case 'notification.new':
        ref.invalidate(notificationsProvider);
        final n = asMap(d['notification'] ?? d);
        final t = '${n['title'] ?? ''}';
        // Los mensajes de chat ya se avisan aparte (o se ven en la pantalla de chat abierta).
        if (n['type'] == 'message.new') break;
        if (t.isNotEmpty) showSnack(null, t);
        break;
    }
  }
}
