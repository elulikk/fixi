import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/state/providers.dart';
import '../../core/widgets/common.dart';
import '../client/client_screens.dart';
import '../profile/profile_screens.dart';
import '../tech/tech_screens.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tech = ref.watch(settingsProvider.select((s) => s.techMode));
    final isTech = ref.watch(authProvider.select((s) => s.user?.isTechnician ?? false));
    final techMode = tech && isTech;
    return AnimatedSwitcher(
      duration: 350.ms,
      switchInCurve: Curves.easeOutCubic,
      child: techMode ? const _TechShell(key: ValueKey('tech')) : const _ClientShell(key: ValueKey('client')),
    );
  }
}

class _ClientShell extends ConsumerWidget {
  const _ClientShell({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = ref.watch(clientTabProvider);
    return Scaffold(
      body: IndexedStack(index: idx, children: const [HomeTab(), ExploreTab(), OrdersTab(), ProfileTab()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          tap();
          ref.read(clientTabProvider.notifier).state = i;
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore_rounded), label: 'Explorar'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Pedidos'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _TechShell extends ConsumerWidget {
  const _TechShell({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = ref.watch(techTabProvider);
    // Mantiene vivo el envío de ubicación mientras haya trabajos "en camino".
    final sender = ref.watch(locationSenderProvider);
    ref.listen<AsyncValue<List<Job>>>(jobsProvider('tech'), (_, n) {
      final v = n.valueOrNull;
      if (v != null) sender.sync(v);
    });
    ref.watch(jobsProvider('tech'));
    return Scaffold(
      body: IndexedStack(index: idx, children: const [TechDashboardTab(), OpportunitiesTab(), TechJobsTab(), ProfileTab()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          tap();
          ref.read(techTabProvider.notifier).state = i;
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Panel'),
          NavigationDestination(icon: Icon(Icons.radar_outlined), selectedIcon: Icon(Icons.radar_rounded), label: 'Oportunidades'),
          NavigationDestination(icon: Icon(Icons.handyman_outlined), selectedIcon: Icon(Icons.handyman_rounded), label: 'Trabajos'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}

/// Selector Cliente / Técnico (persistente).
class ModeSwitch extends ConsumerWidget {
  const ModeSwitch({super.key, this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final techMode = ref.watch(settingsProvider.select((s) => s.techMode));
    if (!(user?.isTechnician ?? false)) return const SizedBox.shrink();
    final cs = context.cs;
    Widget seg(String label, IconData icon, bool sel, String mode) => Expanded(
          child: GestureDetector(
            onTap: () {
              if (sel) return;
              bump();
              ref.read(settingsProvider.notifier).setMode(mode);
            },
            child: AnimatedContainer(
              duration: 250.ms,
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(vertical: large ? 12 : 7, horizontal: large ? 12 : 10),
              decoration: BoxDecoration(color: sel ? cs.primary : Colors.transparent, borderRadius: BorderRadius.circular(99)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: large ? 20 : 16, color: sel ? cs.onPrimary : cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: large ? 15 : 13, color: sel ? cs.onPrimary : cs.onSurfaceVariant)),
              ]),
            ),
          ),
        );
    return Container(
      width: large ? double.infinity : 220,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: cs.surfaceVariant, borderRadius: BorderRadius.circular(99)),
      child: Row(children: [
        seg('Cliente', Icons.person_rounded, !techMode, 'client'),
        seg('Técnico', Icons.handyman_rounded, techMode, 'tech'),
      ]),
    );
  }
}

class BellButton extends ConsumerWidget {
  const BellButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(notificationsProvider).valueOrNull?.where((e) => !e.read).length ?? 0;
    return IconButton(
      onPressed: () {
        tap();
        context.push('/notifications');
      },
      icon: Badge(isLabelVisible: n > 0, label: Text(n > 9 ? '9+' : '$n'), child: const Icon(Icons.notifications_none_rounded, size: 28)),
    );
  }
}
