import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api/api_client.dart';
import '../../core/config/constants.dart';
import '../../core/models/models.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/format.dart';
import '../../core/widgets/common.dart';
import '../shared/cards.dart';
import '../shared/shell.dart';

ListingsQuery _homeQuery(GeoPoint g) => ListingsQuery(lat: g.ll.latitude, lng: g.ll.longitude, radiusKm: 20);

// ============================================================ INICIO
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    return h < 6 ? 'Buenas noches' : (h < 13 ? 'Buen día' : (h < 20 ? 'Buenas tardes' : 'Buenas noches'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final loc = ref.watch(locationProvider);
    final cats = ref.watch(categoriesProvider);
    final jobs = ref.watch(jobsProvider('client'));
    final geo = loc.valueOrNull;
    final listings = geo == null ? null : ref.watch(listingsProvider(_homeQuery(geo)));
    final activeJobs = (jobs.valueOrNull ?? []).where((j) => j.isActive).toList();
    final cs = context.cs;

    Future<void> refresh() async {
      ref.invalidate(locationProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(jobsProvider);
      ref.invalidate(listingsProvider);
      ref.invalidate(notificationsProvider);
      await ref.read(categoriesProvider.future).catchError((_) => <Category>[]);
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${_greeting()}, ${user?.firstName ?? ''}', style: context.tt.headlineSmall),
                        const SizedBox(height: 4),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            tap();
                            ref.invalidate(locationProvider);
                            showSnack(context, 'Actualizando tu ubicación…');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.location_on_rounded, size: 18, color: cs.primary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(loc.when(data: (g) => g.label, loading: () => 'Buscando tu ubicación…', error: (_, __) => 'Sin ubicación'),
                                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                              ),
                              Icon(Icons.refresh_rounded, size: 16, color: cs.onSurfaceVariant),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                    const BellButton(),
                  ]),
                  if (user?.isTechnician ?? false) ...[const SizedBox(height: 8), const Padding(padding: EdgeInsets.only(right: 12), child: ModeSwitch())],
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: TextField(
                      textInputAction: TextInputAction.search,
                      onSubmitted: (v) {
                        ref.read(exploreQueryProvider.notifier).state = v.trim();
                        ref.read(exploreCategoryProvider.notifier).state = null;
                        ref.read(clientTabProvider.notifier).state = 1;
                      },
                      decoration: const InputDecoration(hintText: '¿Qué necesitás arreglar?', prefixIcon: Icon(Icons.search_rounded)),
                    ),
                  ),
                ]),
              ),
            ),
            if (activeJobs.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _ActiveJobCard(job: activeJobs.first, extra: activeJobs.length - 1),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: GradientCard(
                  onTap: () => context.push('/need/new'),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('¿Algo no funciona?', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text('Publicá tu necesidad y recibí ofertas de técnicos cerca tuyo.', style: TextStyle(color: Colors.white.withOpacity(.88), height: 1.35)),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: FixiColors.lime, borderRadius: BorderRadius.circular(99)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('Publicar necesidad', style: TextStyle(color: FixiColors.ink, fontWeight: FontWeight.w800)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 18, color: FixiColors.ink),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.build_circle_rounded, size: 76, color: Colors.white24),
                  ]),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: .1),
              ),
            ),
            const SliverToBoxAdapter(child: SectionHeader('¿Qué necesitás?')),
            SliverToBoxAdapter(
              child: cats.when(
                loading: () => const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Skeleton(height: 220, radius: 20)),
                error: (e, _) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _InlineError(e, () => ref.invalidate(categoriesProvider))),
                data: (list) => _CategoryGroups(list, onPick: (c) {
                  ref.read(exploreCategoryProvider.notifier).state = c.id;
                  ref.read(exploreQueryProvider.notifier).state = '';
                  ref.read(clientTabProvider.notifier).state = 1;
                }),
              ),
            ),
            SliverToBoxAdapter(
              child: SectionHeader('Técnicos cerca tuyo', action: 'Ver todos', onAction: () => ref.read(clientTabProvider.notifier).state = 1),
            ),
            if (listings == null)
              const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: SkeletonCard()))
            else
              listings.when(
                loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Column(children: [SkeletonCard(), SizedBox(height: 12), SkeletonCard()]))),
                error: (e, _) => SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _InlineError(e, () => ref.invalidate(listingsProvider)))),
                data: (items) => items.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Text('Todavía no hay técnicos publicados cerca tuyo. Publicá tu necesidad y ellos te van a ofertar.', style: TextStyle(color: cs.onSurfaceVariant)))),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList.separated(
                          itemCount: math.min(items.length, 4),
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (c, i) => ListingCard(listing: items[i], onTap: () => context.push('/listing', extra: items[i]))
                              .animate(delay: (60 * i).ms)
                              .fadeIn()
                              .slideY(begin: .08),
                        ),
                      ),
              ),
            const SliverToBoxAdapter(child: SectionHeader('Accesos rápidos')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  _Quick(Icons.add_circle_rounded, 'Publicar', () => context.push('/need/new')),
                  const SizedBox(width: 12),
                  _Quick(Icons.receipt_long_rounded, 'Mis pedidos', () => ref.read(clientTabProvider.notifier).state = 2),
                  const SizedBox(width: 12),
                  _Quick(Icons.help_outline_rounded, 'Ayuda', () => context.push('/help')),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(rLg),
            onTap: () {
              tap();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(children: [Icon(icon, color: context.cs.primary, size: 28), const SizedBox(height: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))]),
            ),
          ),
        ),
      );
}

class _InlineError extends StatelessWidget {
  const _InlineError(this.error, this.onRetry);
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Icon(Icons.cloud_off_rounded, color: FixiColors.error),
            const SizedBox(width: 12),
            Expanded(child: Text(errorText(error), style: const TextStyle(fontSize: 13.5))),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ]),
        ),
      );
}

class _CategoryGroups extends StatelessWidget {
  const _CategoryGroups(this.cats, {required this.onPick});
  final List<Category> cats;
  final void Function(Category) onPick;
  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Category>>{};
    for (final c in cats) {
      groups.putIfAbsent(c.group, () => []).add(c);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final e in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
            child: Text(e.key.toUpperCase(), style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w800, color: context.cs.onSurfaceVariant)),
          ),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: .78,
            children: [for (final c in e.value) CategoryTile(category: c, onTap: () => onPick(c))],
          ),
        ],
      ]),
    ).animate().fadeIn(duration: 350.ms);
  }
}

class _ActiveJobCard extends StatelessWidget {
  const _ActiveJobCard({required this.job, required this.extra});
  final Job job;
  final int extra;
  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final (label, _) = StatusPill.spec(job.status);
    final pay = job.status == 'pending_payment';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(rLg),
        onTap: () {
          tap();
          context.push(pay ? '/job/${job.id}/pay' : '/job/${job.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: FixiColors.lime, borderRadius: BorderRadius.circular(16)),
              child: Icon(job.status == 'on_the_way' ? Icons.directions_run_rounded : Icons.handyman_rounded, color: FixiColors.ink),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 900.ms),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Trabajo activo${extra > 0 ? '  ·  +$extra más' : ''}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.primary)),
                const SizedBox(height: 2),
                Text(job.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium),
                Text(pay ? 'Falta pagar para confirmar' : label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
      ),
    ).animate().fadeIn().slideY(begin: .1);
  }
}

// ============================================================ EXPLORAR
class ExploreTab extends ConsumerStatefulWidget {
  const ExploreTab({super.key});
  @override
  ConsumerState<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends ConsumerState<ExploreTab> {
  bool _map = false;
  String _sort = 'best';
  double _radius = 20;
  final _search = TextEditingController();
  Listing? _selected;
  final _mapCtrl = MapController();

  static const sorts = [('best', 'Mejor opción'), ('price', 'Precio'), ('distance', 'Cercanía'), ('eta', 'Tiempo'), ('rating', 'Reputación')];

  LatLng _positionFor(Listing l, LatLng me) {
    if (l.lat != null && l.lng != null) return LatLng(l.lat!, l.lng!);
    // Aproximación: el contrato no incluye coordenadas del técnico; usamos distancia + rumbo estable.
    final bearing = (l.id.codeUnits.fold<int>(0, (a, b) => a * 31 + b) % 360) * math.pi / 180;
    final d = (l.distanceKm ?? 1) / 111.0;
    return LatLng(me.latitude + d * math.cos(bearing), me.longitude + d * math.sin(bearing) / math.cos(me.latitude * math.pi / 180));
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final geo = ref.watch(locationProvider).valueOrNull;
    final catId = ref.watch(exploreCategoryProvider);
    final q = ref.watch(exploreQueryProvider);
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    if (_search.text != q && q.isNotEmpty) _search.text = q;
    final me = geo?.ll ?? AppConst.obelisco;
    final query = ListingsQuery(lat: me.latitude, lng: me.longitude, radiusKm: _radius, categoryId: catId, q: q, sort: _sort);
    final res = ref.watch(listingsProvider(query));

    return SafeArea(
      bottom: false,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(children: [
            Expanded(child: Text('Explorar servicios', style: context.tt.headlineSmall)),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
              segments: const [ButtonSegment(value: false, icon: Icon(Icons.view_agenda_rounded, size: 18)), ButtonSegment(value: true, icon: Icon(Icons.map_rounded, size: 18))],
              selected: {_map},
              onSelectionChanged: (s) {
                tap();
                setState(() => _map = s.first);
              },
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => ref.read(exploreQueryProvider.notifier).state = v.trim(),
            decoration: InputDecoration(
              hintText: 'Buscar servicio o técnico',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: q.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _search.clear();
                        ref.read(exploreQueryProvider.notifier).state = '';
                      }),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
            _chip('Todas', catId == null, () => ref.read(exploreCategoryProvider.notifier).state = null),
            for (final c in cats) _chip(c.name, catId == c.id, () => ref.read(exploreCategoryProvider.notifier).state = c.id),
          ]),
        ),
        SizedBox(
          height: 48,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), children: [
            ActionChip(
              avatar: const Icon(Icons.tune_rounded, size: 18),
              label: Text('${_radius.round()} km'),
              onPressed: () async {
                final r = await showModalBottomSheet<double>(
                  context: context,
                  builder: (c) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Radio de búsqueda', style: context.tt.titleLarge),
                        const SizedBox(height: 16),
                        Wrap(spacing: 10, runSpacing: 10, children: [
                          for (final v in [2.0, 5.0, 10.0, 20.0, 50.0])
                            ChoiceChip(label: Text('${v.round()} km'), selected: _radius == v, onSelected: (_) => Navigator.pop(c, v)),
                        ]),
                      ]),
                    ),
                  ),
                );
                if (r != null) setState(() => _radius = r);
              },
            ),
            const SizedBox(width: 8),
            for (final (code, label) in sorts)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: _sort == code,
                  showCheckmark: false,
                  labelStyle: TextStyle(color: _sort == code ? cs.onPrimary : null, fontWeight: FontWeight.w700),
                  onSelected: (_) {
                    tap();
                    setState(() => _sort = code);
                  },
                ),
              ),
          ]),
        ),
        Expanded(
          child: AsyncBody<List<Listing>>(
            value: res,
            onRetry: () async => ref.refresh(listingsProvider(query).future),
            builder: (items) {
              if (items.isEmpty) {
                return EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No encontramos servicios',
                  message: 'Probá ampliando el radio, cambiando la categoría o publicá tu necesidad para que los técnicos te ofrezcan.',
                  actionLabel: 'Publicar necesidad',
                  onAction: () => context.push('/need/new'),
                );
              }
              if (_map) return _mapView(items, me);
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (c, i) => ListingCard(listing: items[i], onTap: () => context.push('/listing', extra: items[i])).animate(delay: (40 * math.min(i, 8)).ms).fadeIn().slideY(begin: .06),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _chip(String label, bool sel, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: sel,
          showCheckmark: false,
          labelStyle: TextStyle(color: sel ? context.cs.onPrimary : null, fontWeight: FontWeight.w700),
          onSelected: (_) {
            tap();
            onTap();
          },
        ),
      );

  Widget _mapView(List<Listing> items, LatLng me) {
    return Stack(children: [
      FixiMap(
        center: me,
        zoom: 13,
        controller: _mapCtrl,
        onTap: () => setState(() => _selected = null),
        markers: [
          pinMarker(me, Icons.person_pin_circle_rounded, FixiColors.primary, size: 40),
          for (final l in items)
            labelMarker(_positionFor(l, me), money(l.price), FixiColors.primary, selected: _selected?.id == l.id, onTap: () {
              tap();
              setState(() => _selected = l);
            }),
        ],
      ),
      if (_selected != null)
        Positioned(left: 16, right: 16, bottom: 16, child: ListingCard(listing: _selected!, onTap: () => context.push('/listing', extra: _selected)).animate().fadeIn().slideY(begin: .2)),
    ]);
  }
}

// ============================================================ PEDIDOS
class OrdersTab extends ConsumerStatefulWidget {
  const OrdersTab({super.key});
  @override
  ConsumerState<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends ConsumerState<OrdersTab> with SingleTickerProviderStateMixin {
  late final _tc = TabController(length: 2, vsync: this);
  bool _history = false;

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    return SafeArea(
      bottom: false,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
          child: Row(children: [
            Expanded(child: Text('Mis pedidos', style: context.tt.headlineSmall)),
            FilledButton.icon(
              onPressed: () => context.push('/need/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Publicar'),
              style: FilledButton.styleFrom(minimumSize: const Size(110, 42)),
            ),
            const BellButton(),
          ]),
        ),
        TabBar(controller: _tc, dividerColor: context.cs.outlineVariant, tabs: const [Tab(text: 'Necesidades'), Tab(text: 'Trabajos')]),
        Expanded(
          child: TabBarView(controller: _tc, children: [
            AsyncBody<List<NeedRequest>>(
              value: ref.watch(myRequestsProvider),
              onRetry: () async => ref.refresh(myRequestsProvider.future),
              builder: (items) => items.isEmpty
                  ? EmptyState(icon: Icons.post_add_rounded, title: 'Todavía no publicaste nada', message: 'Contanos qué necesitás y los técnicos cercanos te mandan sus ofertas.', actionLabel: 'Publicar necesidad', onAction: () => context.push('/need/new'))
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (c, i) => RequestCard(request: items[i], categories: cats, onTap: () => context.push('/need/${items[i].id}')).animate(delay: (40 * math.min(i, 8)).ms).fadeIn(),
                    ),
            ),
            AsyncBody<List<Job>>(
              value: ref.watch(jobsProvider('client')),
              onRetry: () async => ref.refresh(jobsProvider('client').future),
              builder: (all) {
                final items = all.where((j) => _history ? !j.isActive : j.isActive).toList();
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: const [ButtonSegment(value: false, label: Text('Activos')), ButtonSegment(value: true, label: Text('Historial'))],
                      selected: {_history},
                      onSelectionChanged: (s) => setState(() => _history = s.first),
                    ),
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? EmptyState(
                            icon: _history ? Icons.history_rounded : Icons.handyman_rounded,
                            title: _history ? 'Sin historial todavía' : 'No tenés trabajos activos',
                            message: _history ? 'Cuando completes un trabajo lo vas a ver acá.' : 'Cuando aceptes una oferta o reserves un servicio, lo seguís desde acá.',
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (c, i) => JobCard(job: items[i], clientView: true, onTap: () => context.push(items[i].status == 'pending_payment' ? '/job/${items[i].id}/pay' : '/job/${items[i].id}')),
                          ),
                  ),
                ]);
              },
            ),
          ]),
        ),
      ]),
    );
  }
}

// ============================================================ DETALLE DE SERVICIO + RESERVA
class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = listing;
    final t = l.tech;
    final cs = context.cs;
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final cat = cats.where((c) => c.id == l.categoryId).firstOrNull;
    final me = ref.watch(authProvider).user;
    final own = me?.id == l.techId;
    return Scaffold(
      appBar: AppBar(title: const Text('Servicio')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 120), children: [
        if (l.badges.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 12), child: Wrap(spacing: 6, runSpacing: 6, children: l.badges.map((b) => BadgeChip(b)).toList())),
        if (cat != null) Text(cat.name.toUpperCase(), style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w800, color: cs.primary)),
        const SizedBox(height: 6),
        Text(l.title, style: context.tt.headlineSmall),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(l.pricePrefix, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
          Text(money(l.price), style: context.tt.headlineLarge?.copyWith(color: cs.primary, fontSize: 36)),
          Text(l.priceSuffix, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: InfoTile(icon: Icons.near_me_rounded, label: 'Distancia', value: fmtDistance(l.distanceKm ?? t?.distanceKm))),
          const SizedBox(width: 10),
          Expanded(child: InfoTile(icon: Icons.schedule_rounded, label: 'Llega', value: l.etaMinutes == null ? '—' : fmtMinutes(l.etaMinutes), color: FixiColors.warning)),
          const SizedBox(width: 10),
          Expanded(child: InfoTile(icon: Icons.timer_outlined, label: 'Duración', value: fmtMinutes(l.durationMinutes), color: FixiColors.success)),
        ]),
        if (l.description.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('Qué incluye', style: context.tt.titleMedium),
          const SizedBox(height: 8),
          Text(l.description, style: TextStyle(height: 1.5, color: cs.onSurfaceVariant, fontSize: 15)),
        ],
        const SizedBox(height: 22),
        if (t != null)
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(rLg),
              onTap: () => context.push('/t/${t.userId}'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  FixiAvatar(url: t.avatarUrl, name: t.name, size: 56, heroTag: 'tech-${t.userId}'),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Flexible(child: Text(t.name, style: context.tt.titleMedium)), if (t.verified) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified_rounded, size: 18, color: FixiColors.primary))]),
                      const SizedBox(height: 6),
                      Wrap(spacing: 10, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [RatingChip(t.ratingAvg, t.ratingCount), LevelBadge(t.level, compact: true), Text('${t.jobsDone} trabajos', style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant))]),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ]),
              ),
            ),
          ),
        const SizedBox(height: 16),
        const _ProtectionNote(),
      ]),
      bottomSheet: own
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(color: cs.surface, border: Border(top: BorderSide(color: cs.outlineVariant))),
              child: AppButton(label: 'Reservar por ${money(l.price)}', icon: Icons.bolt_rounded, onPressed: () => _bookSheet(context, ref, l)),
            ),
    );
  }

  Future<void> _bookSheet(BuildContext context, WidgetRef ref, Listing l) async {
    final job = await showModalBottomSheet<Job>(
      context: context,
      isScrollControlled: true,
      builder: (c) => _BookSheet(listing: l),
    );
    if (job != null && context.mounted) context.push('/job/${job.id}/pay');
  }
}

class _ProtectionNote extends StatelessWidget {
  const _ProtectionNote();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: FixiColors.success.withOpacity(.1), borderRadius: BorderRadius.circular(rMd)),
        child: const Row(children: [
          Icon(Icons.shield_rounded, color: FixiColors.success),
          SizedBox(width: 12),
          Expanded(child: Text('Pago protegido: el dinero se libera al técnico recién cuando confirmás que el trabajo está terminado.', style: TextStyle(fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w500))),
        ]),
      );
}

class _BookSheet extends ConsumerStatefulWidget {
  const _BookSheet({required this.listing});
  final Listing listing;
  @override
  ConsumerState<_BookSheet> createState() => _BookSheetState();
}

class _BookSheetState extends ConsumerState<_BookSheet> {
  late final _addr = TextEditingController(text: ref.read(authProvider).user?.address ?? '');
  final _notes = TextEditingController();
  DateTime? _when;
  bool _busy = false;

  Future<void> _pickWhen() async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, firstDate: now, lastDate: now.add(const Duration(days: 60)), initialDate: now);
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))));
    if (t == null) return;
    setState(() => _when = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _go() async {
    if (_addr.text.trim().length < 5) {
      showSnack(context, 'Escribí la dirección donde necesitás el servicio', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final geo = ref.read(locationProvider).valueOrNull;
      final u = ref.read(authProvider).user;
      final ll = (u?.lat != null && u?.lng != null && (geo?.isDefault ?? true)) ? LatLng(u!.lat!, u.lng!) : (geo?.ll ?? AppConst.obelisco);
      final job = await ref.read(apiProvider).book(widget.listing.id, {
        'address': _addr.text.trim(),
        'lat': ll.latitude,
        'lng': ll.longitude,
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
        if (_when != null) 'scheduledAt': _when!.toUtc().toIso8601String(),
      });
      ref.invalidate(jobsProvider);
      success();
      if (mounted) Navigator.pop(context, job);
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Reservar servicio', style: context.tt.titleLarge),
          const SizedBox(height: 4),
          Text(widget.listing.title, style: TextStyle(color: context.cs.onSurfaceVariant)),
          const SizedBox(height: 18),
          TextField(controller: _addr, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Dirección', prefixIcon: Icon(Icons.location_on_outlined))),
          const SizedBox(height: 12),
          TextField(controller: _notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Notas para el técnico (opcional)', prefixIcon: Icon(Icons.notes_rounded))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ChoiceChip(label: const Center(child: Text('Lo antes posible')), selected: _when == null, onSelected: (_) => setState(() => _when = null))),
            const SizedBox(width: 8),
            Expanded(child: ChoiceChip(label: Center(child: Text(_when == null ? 'Elegir día y hora' : fmtDateTime(_when))), selected: _when != null, onSelected: (_) => _pickWhen())),
          ]),
          const SizedBox(height: 20),
          AppButton(label: 'Continuar al pago · ${money(widget.listing.price)}', loading: _busy, onPressed: _go),
        ]),
      ),
    );
  }
}

// ============================================================ PERFIL PÚBLICO DEL TÉCNICO
class TechPublicScreen extends ConsumerWidget {
  const TechPublicScreen({super.key, required this.id, this.heroSeed});
  final String id;
  final String? heroSeed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final res = ref.watch(techPublicProvider(id));
    final cs = context.cs;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil del técnico')),
      body: AsyncBody<TechPublic>(
        value: res,
        onRetry: () async => ref.refresh(techPublicProvider(id).future),
        builder: (d) {
          final t = d.tech;
          final p = d.profile;
          final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
          final next = Levels.nextThreshold(t.points);
          return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [
            Center(child: FixiAvatar(url: t.avatarUrl, name: t.name, size: 96, heroTag: 'tech-${t.userId}')),
            const SizedBox(height: 14),
            Center(child: Row(mainAxisSize: MainAxisSize.min, children: [Flexible(child: Text(t.name, style: context.tt.headlineSmall)), if (t.verified) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.verified_rounded, color: FixiColors.primary))])),
            const SizedBox(height: 8),
            Center(child: LevelBadge(t.level)),
            if (p != null && p.bio.isNotEmpty) ...[const SizedBox(height: 14), Text(p.bio, textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant, height: 1.5, fontSize: 15))],
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: InfoTile(icon: Icons.star_rounded, label: '${t.ratingCount} reseñas', value: t.ratingCount == 0 ? 'Nuevo' : t.ratingAvg.toStringAsFixed(1), color: FixiColors.warning)),
              const SizedBox(width: 10),
              Expanded(child: InfoTile(icon: Icons.task_alt_rounded, label: 'Trabajos', value: '${t.jobsDone}', color: FixiColors.success)),
              const SizedBox(width: 10),
              Expanded(child: InfoTile(icon: Icons.workspace_premium_rounded, label: next == null ? 'Nivel máximo' : 'Puntos', value: '${t.points}', color: FixiColors.level(t.level))),
            ]),
            if (p != null && p.categoryIds.isNotEmpty) ...[
              const SizedBox(height: 18),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final cid in p.categoryIds)
                  if (cats.where((c) => c.id == cid).isNotEmpty) Chip(avatar: Icon(categoryIcon(cats.firstWhere((c) => c.id == cid).icon), size: 16), label: Text(cats.firstWhere((c) => c.id == cid).name)),
              ]),
            ],
            if (d.listings.isNotEmpty) ...[
              const SectionHeader('Servicios', padding: EdgeInsets.fromLTRB(0, 26, 0, 12)),
              for (final l in d.listings.where((l) => l.active)) Padding(padding: const EdgeInsets.only(bottom: 12), child: ListingCard(listing: l, compact: true, onTap: () => context.push('/listing', extra: l))),
            ],
            SectionHeader('Reseñas (${d.reviews.length})', padding: const EdgeInsets.fromLTRB(0, 18, 0, 12)),
            if (d.reviews.isEmpty)
              Card(child: Padding(padding: const EdgeInsets.all(20), child: Text('Todavía no tiene reseñas. ¡Podés ser el primero en calificarlo!', style: TextStyle(color: cs.onSurfaceVariant))))
            else
              for (final r in d.reviews)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [StarsRow(r.rating, size: 17), const Spacer(), Text(timeAgo(r.createdAt), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))]),
                        if (r.fromName != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(r.fromName!, style: const TextStyle(fontWeight: FontWeight.w700))),
                        if (r.comment.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(r.comment, style: const TextStyle(height: 1.4))),
                      ]),
                    ),
                  ),
                ),
          ]);
        },
      ),
    );
  }
}
