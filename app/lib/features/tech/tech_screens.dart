import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/config/constants.dart';
import '../../core/models/models.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/format.dart';
import '../../core/widgets/common.dart';
import '../shared/cards.dart';
import '../shared/shell.dart';

Future<void> _saveAvailability(WidgetRef ref, BuildContext context, TechProfile p, bool v) async {
  try {
    await ref.read(apiProvider).putTechProfile({'bio': p.bio, 'categoryIds': p.categoryIds, 'radiusKm': p.radiusKm, 'available': v});
    ref.read(authProvider.notifier).setTech(p.copyWith(available: v));
    if (v) {
      success();
    } else {
      tap();
    }
    if (context.mounted) showSnack(context, v ? 'Estás disponible: te llegan oportunidades' : 'Pausaste tu disponibilidad', ok: v);
    ref.read(authProvider.notifier).refresh();
  } catch (e) {
    if (context.mounted) showSnack(context, errorText(e), error: true);
  }
}

Future<void> _connectMp(WidgetRef ref, BuildContext context) async {
  try {
    final url = await ref.read(apiProvider).connectUrl();
    if (url == null) throw const ApiException('NO_URL', 'El servidor no devolvió el link de vinculación.');
    final base = ref.read(settingsProvider).baseUrl;
    var u = Uri.parse(url);
    final b = Uri.parse(base);
    if (const ['localhost', '127.0.0.1'].contains(u.host)) u = u.replace(host: b.host);
    await launchUrl(u, mode: LaunchMode.externalApplication);
    if (context.mounted) showSnack(context, 'Cuando termines, volvé a Fixi y actualizá el panel.');
  } catch (e) {
    if (context.mounted) showSnack(context, errorText(e), error: true);
  }
}

// ============================================================ PANEL
class TechDashboardTab extends ConsumerWidget {
  const TechDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final p = auth.tech;
    final earn = ref.watch(earningsProvider);
    final jobs = ref.watch(jobsProvider('tech'));
    final cs = context.cs;
    Future<void> refresh() async {
      ref.invalidate(earningsProvider);
      ref.invalidate(jobsProvider);
      ref.invalidate(notificationsProvider);
      await ref.read(authProvider.notifier).refresh();
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
          Row(children: [
            Expanded(child: Text('Hola, ${auth.user?.firstName ?? ''}', style: context.tt.headlineSmall)),
            const BellButton(),
          ]),
          const SizedBox(height: 8),
          const ModeSwitch(),
          const SizedBox(height: 18),
          if (p == null)
            Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [const Text('Todavía no completaste tu perfil técnico.'), const SizedBox(height: 12), AppButton(label: 'Completar perfil', onPressed: () => context.push('/tech-setup'))])))
          else ...[
            _AvailabilityCard(p: p),
            const SizedBox(height: 14),
            if (!p.paymentsConnected) _MpCard(connected: false) else _MpCard(connected: true),
            const SizedBox(height: 6),
            const SectionHeader('Tus ganancias', padding: EdgeInsets.fromLTRB(0, 18, 0, 12)),
            earn.when(
              loading: () => const Skeleton(height: 150, radius: 24),
              error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: Text(errorText(e))), TextButton(onPressed: () => ref.invalidate(earningsProvider), child: const Text('Reintentar'))]))),
              data: (e) => Column(children: [
                GradientCard(
                  colors: const [Color(0xFF0E1320), Color(0xFF26335E)],
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Ganado (neto)', style: TextStyle(color: Colors.white.withOpacity(.7), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(money(e.totalNet), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _MiniStat('A cobrar', money(e.pendingNet), FixiColors.lime)),
                      Expanded(child: _MiniStat('Comisión Fixi pagada', money(e.commissionPaid), Colors.white70)),
                    ]),
                  ]),
                ).animate().fadeIn().slideY(begin: .08),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(rLg)),
                  child: Row(children: [
                    Icon(Icons.info_outline_rounded, color: cs.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Fixi cobra ${AppConst.commissionPercent}% por trabajo, solo si cobrás. En un servicio de ${money(10000)} recibís ${money(techNetOf(10000))}.', style: const TextStyle(height: 1.35, fontWeight: FontWeight.w500))),
                  ]),
                ),
              ]),
            ),
            const SectionHeader('Tu nivel', padding: EdgeInsets.fromLTRB(0, 24, 0, 12)),
            _LevelCard(p: p),
          ],
          SectionHeader('Trabajos de hoy', action: 'Ver todos', onAction: () => ref.read(techTabProvider.notifier).state = 2, padding: const EdgeInsets.fromLTRB(0, 24, 0, 12)),
          jobs.when(
            loading: () => const SkeletonCard(),
            error: (e, _) => Text(errorText(e)),
            data: (list) {
              final active = list.where((j) => j.isActive && j.status != 'pending_payment').toList();
              if (active.isEmpty) {
                return Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [Icon(Icons.event_available_rounded, size: 40, color: cs.primary), const SizedBox(height: 10), const Text('No tenés trabajos en curso', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text('Mirá las oportunidades cerca tuyo y mandá tu mejor oferta.', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)), const SizedBox(height: 12), OutlinedButton(onPressed: () => ref.read(techTabProvider.notifier).state = 1, style: OutlinedButton.styleFrom(minimumSize: const Size(200, 46)), child: const Text('Ver oportunidades'))])));
              }
              return Column(children: [for (final j in active) Padding(padding: const EdgeInsets.only(bottom: 10), child: JobCard(job: j, clientView: false, onTap: () => context.push('/job/${j.id}')))]);
            },
          ),
          const SectionHeader('Gestioná tu negocio', padding: EdgeInsets.fromLTRB(0, 20, 0, 12)),
          Row(children: [
            Expanded(child: _Shortcut(Icons.local_offer_rounded, 'Mis ofertas', () => context.push('/my-offers'))),
            const SizedBox(width: 12),
            Expanded(child: _Shortcut(Icons.storefront_rounded, 'Mis servicios', () => context.push('/my-listings'))),
          ]),
        ]),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, this.color);
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: Colors.white.withOpacity(.65), fontSize: 12)), const SizedBox(height: 2), Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18))]);
}

class _Shortcut extends StatelessWidget {
  const _Shortcut(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(rLg),
          onTap: () {
            tap();
            onTap();
          },
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Column(children: [Icon(icon, color: context.cs.primary, size: 30), const SizedBox(height: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w700))])),
        ),
      );
}

class _AvailabilityCard extends ConsumerWidget {
  const _AvailabilityCard({required this.p});
  final TechProfile p;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = p.available;
    return AnimatedContainer(
      duration: 300.ms,
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
      decoration: BoxDecoration(
        color: on ? FixiColors.success.withOpacity(.12) : context.cs.surface,
        borderRadius: BorderRadius.circular(rXl),
        border: Border.all(color: on ? FixiColors.success.withOpacity(.5) : context.cs.outlineVariant),
      ),
      child: Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: on ? FixiColors.success : context.cs.outline, shape: BoxShape.circle)).animate(target: on ? 1 : 0, onPlay: (c) => on ? c.repeat(reverse: true) : null).fade(begin: .4, end: 1, duration: 900.ms),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(on ? 'Disponible' : 'No disponible', style: context.tt.titleMedium), Text(on ? 'Estás recibiendo oportunidades cerca tuyo' : 'No te llegan avisos de nuevas necesidades', style: TextStyle(fontSize: 12.5, color: context.cs.onSurfaceVariant))])),
        Switch.adaptive(value: on, onChanged: (v) => _saveAvailability(ref, context, p, v)),
      ]),
    );
  }
}

class _MpCard extends ConsumerWidget {
  const _MpCard({required this.connected});
  final bool connected;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = connected ? FixiColors.success : FixiColors.warning;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.withOpacity(.12), borderRadius: BorderRadius.circular(rLg), border: Border.all(color: c.withOpacity(.4))),
      child: Row(children: [
        Icon(connected ? Icons.verified_rounded : Icons.account_balance_wallet_rounded, color: c),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(connected ? 'Mercado Pago vinculado' : 'Vinculá Mercado Pago', style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(connected ? 'Vas a cobrar tus trabajos en tu cuenta.' : 'Lo necesitás para cobrar tus trabajos.', style: TextStyle(fontSize: 12.5, color: context.cs.onSurfaceVariant)),
        ])),
        if (!connected) FilledButton(onPressed: () => _connectMp(ref, context), style: FilledButton.styleFrom(minimumSize: const Size(96, 42), backgroundColor: FixiColors.warning, foregroundColor: FixiColors.ink), child: const Text('Vincular')),
        if (connected) TextButton(onPressed: () => ref.read(authProvider.notifier).refresh(), child: const Text('Actualizar')),
      ]),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.p});
  final TechProfile p;
  @override
  Widget build(BuildContext context) {
    final next = Levels.nextThreshold(p.points);
    final nextName = next == null ? null : Levels.names[Levels.thresholds.indexOf(next)];
    final cs = context.cs;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [LevelBadge(p.level), const Spacer(), Text('${p.points} pts', style: context.tt.titleLarge)]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: Levels.progress(p.points)),
              duration: 800.ms,
              curve: Curves.easeOutCubic,
              builder: (c, v, _) => LinearProgressIndicator(value: v, minHeight: 10, backgroundColor: cs.surfaceVariant, color: FixiColors.level(nextName ?? p.level)),
            ),
          ),
          const SizedBox(height: 8),
          Text(next == null ? '¡Llegaste al nivel máximo!' : 'Te faltan ${next - p.points} puntos para ${Levels.label(nextName!)}', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: InfoTile(icon: Icons.star_rounded, label: '${p.ratingCount} reseñas', value: p.ratingCount == 0 ? 'Nuevo' : p.ratingAvg.toStringAsFixed(1), color: FixiColors.warning)),
            const SizedBox(width: 8),
            Expanded(child: InfoTile(icon: Icons.task_alt_rounded, label: 'Trabajos', value: '${p.jobsDone}', color: FixiColors.success)),
          ]),
          const SizedBox(height: 4),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: const ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('¿Cómo sumo puntos?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              children: [
                Align(alignment: Alignment.centerLeft, child: Text('•  +20 por cada trabajo completado\n•  +10 × (estrellas − 3) por cada reseña: 5★ suma 20, 1★ resta 20\n•  +5 si llegás dentro del tiempo prometido\n\nNiveles: Bronce 0+ · Plata 200+ · Oro 600+ · Platino 1500+', style: TextStyle(height: 1.5))),
                SizedBox(height: 8),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ============================================================ OPORTUNIDADES
class OpportunitiesTab extends ConsumerStatefulWidget {
  const OpportunitiesTab({super.key});
  @override
  ConsumerState<OpportunitiesTab> createState() => _OpportunitiesTabState();
}

class _OpportunitiesTabState extends ConsumerState<OpportunitiesTab> {
  bool _map = false;
  String? _cat;
  NeedRequest? _sel;

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(authProvider).tech;
    final geo = ref.watch(locationProvider).valueOrNull;
    final me = geo?.ll ?? AppConst.obelisco;
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final myCats = p == null || p.categoryIds.isEmpty ? cats : cats.where((c) => p.categoryIds.contains(c.id)).toList();
    final q = NearbyQuery(me.latitude, me.longitude, p?.radiusKm ?? 15, _cat);
    final res = ref.watch(nearbyProvider(q));
    return SafeArea(
      bottom: false,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(children: [
            Expanded(child: Text('Oportunidades', style: context.tt.headlineSmall)),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
              segments: const [ButtonSegment(value: false, icon: Icon(Icons.view_agenda_rounded, size: 18)), ButtonSegment(value: true, icon: Icon(Icons.map_rounded, size: 18))],
              selected: {_map},
              onSelectionChanged: (s) => setState(() => _map = s.first),
            ),
          ]),
        ),
        if (p != null && !p.available)
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            decoration: BoxDecoration(color: FixiColors.warning.withOpacity(.14), borderRadius: BorderRadius.circular(rMd)),
            child: Row(children: [
              const Icon(Icons.pause_circle_rounded, color: FixiColors.warning),
              const SizedBox(width: 10),
              const Expanded(child: Text('Estás no disponible: no te avisamos de nuevas necesidades.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              TextButton(onPressed: () => _saveAvailability(ref, context, p, true), child: const Text('Activar')),
            ]),
          ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
            Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(label: Text('Todas · ${p?.radiusKm.round() ?? 15} km'), selected: _cat == null, showCheckmark: false, labelStyle: TextStyle(color: _cat == null ? context.cs.onPrimary : null, fontWeight: FontWeight.w700), onSelected: (_) => setState(() => _cat = null))),
            for (final c in myCats) Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(label: Text(c.name), selected: _cat == c.id, showCheckmark: false, labelStyle: TextStyle(color: _cat == c.id ? context.cs.onPrimary : null, fontWeight: FontWeight.w700), onSelected: (_) => setState(() => _cat = c.id))),
          ]),
        ),
        Expanded(
          child: AsyncBody<List<NeedRequest>>(
            value: res,
            onRetry: () async => ref.refresh(nearbyProvider(q).future),
            builder: (items) {
              if (items.isEmpty) {
                return const EmptyState(icon: Icons.radar_rounded, title: 'Sin oportunidades por ahora', message: 'Cuando alguien cerca tuyo publique una necesidad de tus categorías, aparece acá al instante.');
              }
              if (_map) {
                return Stack(children: [
                  FixiMap(center: me, zoom: 12.5, onTap: () => setState(() => _sel = null), markers: [
                    pinMarker(me, Icons.person_pin_circle_rounded, FixiColors.primary, size: 40),
                    for (final r in items) pinMarker(LatLng(r.lat, r.lng), categoryIcon(cats.where((c) => c.id == r.categoryId).firstOrNull?.icon ?? ''), _sel?.id == r.id ? FixiColors.ink : FixiColors.warning),
                  ]),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    height: 150,
                    child: PageView.builder(
                      controller: PageController(viewportFraction: .9),
                      itemCount: items.length,
                      onPageChanged: (i) => setState(() => _sel = items[i]),
                      itemBuilder: (c, i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: RequestCard(request: items[i], categories: cats, showDistance: true, onTap: () => context.push('/opportunity/${items[i].id}', extra: items[i]))),
                    ),
                  ),
                ]);
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (c, i) => RequestCard(request: items[i], categories: cats, showDistance: true, onTap: () => context.push('/opportunity/${items[i].id}', extra: items[i])).animate(delay: (40 * math.min(i, 8)).ms).fadeIn().slideY(begin: .06),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class OpportunityScreen extends ConsumerStatefulWidget {
  const OpportunityScreen({super.key, required this.id, this.initial});
  final String id;
  final NeedRequest? initial;
  @override
  ConsumerState<OpportunityScreen> createState() => _OpportunityScreenState();
}

class _OpportunityScreenState extends ConsumerState<OpportunityScreen> {
  final _price = TextEditingController();
  final _msg = TextEditingController();
  int _eta = 30, _dur = 60;
  bool _busy = false;

  static const templates = ['Tengo experiencia y repuestos a mano.', 'Puedo ir hoy mismo.', 'Incluye revisión y diagnóstico sin cargo.', 'Garantía de 30 días en el trabajo.'];

  int? get _priceVal => int.tryParse(_price.text.replaceAll(RegExp(r'[^0-9]'), ''));

  Future<void> _send(NeedRequest r) async {
    final p = _priceVal;
    if (p == null || p <= 0) {
      showSnack(context, 'Poné un precio para tu oferta', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).sendOffer(r.id, {'price': p, 'etaMinutes': _eta, 'durationMinutes': _dur, 'message': _msg.text.trim()});
      success();
      ref.invalidate(myOffersProvider);
      ref.invalidate(nearbyProvider);
      if (mounted) {
        showSnack(context, '¡Oferta enviada! Te avisamos si te eligen.', ok: true);
        context.pop();
      }
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = ref.watch(requestDetailProvider(widget.id));
    final r = res.valueOrNull?.request ?? widget.initial;
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final mine = ref.watch(myOffersProvider).valueOrNull ?? [];
    final already = mine.where((o) => o.requestId == widget.id && o.status == 'pending').firstOrNull;
    final cs = context.cs;
    return Scaffold(
      appBar: AppBar(title: const Text('Oportunidad')),
      body: r == null
          ? (res.hasError ? ErrorState(error: res.error!, onRetry: () => ref.invalidate(requestDetailProvider(widget.id))) : const SkeletonList())
          : ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), children: [
              Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(categoryIcon(cats.where((c) => c.id == r.categoryId).firstOrNull?.icon ?? ''), color: cs.primary)),
                const SizedBox(width: 12),
                Expanded(child: Text(cats.where((c) => c.id == r.categoryId).firstOrNull?.name ?? '', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700))),
                StatusPill(r.status),
              ]),
              const SizedBox(height: 14),
              Text(r.title, style: context.tt.headlineSmall),
              if (r.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(r.description, style: TextStyle(height: 1.5, color: cs.onSurfaceVariant, fontSize: 15))),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: InfoTile(icon: Icons.near_me_rounded, label: 'Distancia', value: fmtDistance(r.distanceKm))),
                const SizedBox(width: 8),
                Expanded(child: InfoTile(icon: Icons.bolt_rounded, label: 'Urgencia', value: urgencyLabel(r.urgency), color: FixiColors.warning)),
                const SizedBox(width: 8),
                Expanded(child: InfoTile(icon: Icons.payments_rounded, label: 'Tope', value: r.budgetMax == null ? 'Sin tope' : money(r.budgetMax!), color: FixiColors.success)),
              ]),
              if (r.photos.isNotEmpty) ...[
                const SizedBox(height: 14),
                SizedBox(height: 90, child: ListView(scrollDirection: Axis.horizontal, children: [for (final p in r.photos) Padding(padding: const EdgeInsets.only(right: 8), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(p, width: 90, height: 90, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 90))))])),
              ],
              const SizedBox(height: 12),
              ClipRRect(borderRadius: BorderRadius.circular(rLg), child: SizedBox(height: 150, child: FixiMap(center: LatLng(r.lat, r.lng), zoom: 14, interactive: false, markers: [pinMarker(LatLng(r.lat, r.lng), Icons.home_rounded, FixiColors.primary)]))),
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(r.address, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600))),
              const Divider(height: 40),
              if (already != null)
                Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [const Icon(Icons.check_circle_rounded, color: FixiColors.success, size: 30), const SizedBox(width: 12), Expanded(child: Text('Ya mandaste una oferta por ${money(already.price)}. Esperá la respuesta del cliente.', style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35)))])))
              else if (!r.isOpen)
                Card(child: Padding(padding: const EdgeInsets.all(18), child: Text('Esta necesidad ya no está abierta.', style: TextStyle(color: cs.onSurfaceVariant))))
              else ...[
                Text('Tu oferta', style: context.tt.titleLarge),
                const SizedBox(height: 14),
                TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  style: context.tt.headlineSmall,
                  decoration: const InputDecoration(labelText: 'Precio total', prefixText: '\$ '),
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: 250.ms,
                  child: (_priceVal ?? 0) > 0
                      ? Container(
                          key: ValueKey(_priceVal),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: FixiColors.success.withOpacity(.12), borderRadius: BorderRadius.circular(rMd)),
                          child: Row(children: [
                            const Icon(Icons.savings_rounded, color: FixiColors.success),
                            const SizedBox(width: 10),
                            Expanded(child: Text.rich(TextSpan(children: [
                              const TextSpan(text: 'Recibís '),
                              TextSpan(text: money(techNetOf(_priceVal!)), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              TextSpan(text: ' después de la comisión de ${AppConst.commissionPercent}% (${money(commissionOf(_priceVal!))})'),
                            ]), style: const TextStyle(height: 1.35))),
                          ]),
                        )
                      : const SizedBox.shrink(),
                ),
                if (r.budgetMax != null && (_priceVal ?? 0) > r.budgetMax!)
                  Padding(padding: const EdgeInsets.only(top: 8), child: Text('Ojo: tu precio supera el tope del cliente (${money(r.budgetMax!)}).', style: const TextStyle(color: FixiColors.warning, fontWeight: FontWeight.w700, fontSize: 13))),
                const SizedBox(height: 18),
                Text('¿En cuánto llegás?', style: context.tt.titleSmall),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final v in [15, 30, 45, 60, 90, 120]) ChoiceChip(label: Text(fmtMinutes(v)), selected: _eta == v, onSelected: (_) => setState(() => _eta = v))]),
                const SizedBox(height: 18),
                Text('¿Cuánto dura el trabajo?', style: context.tt.titleSmall),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final v in [30, 60, 90, 120, 180, 240]) ChoiceChip(label: Text(fmtMinutes(v)), selected: _dur == v, onSelected: (_) => setState(() => _dur = v))]),
                const SizedBox(height: 18),
                Text('Mensaje para el cliente', style: context.tt.titleSmall),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final t in templates) ActionChip(label: Text(t, style: const TextStyle(fontSize: 12.5)), onPressed: () => setState(() => _msg.text = _msg.text.isEmpty ? t : '${_msg.text} $t'))]),
                const SizedBox(height: 10),
                TextField(controller: _msg, minLines: 3, maxLines: 5, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Contale por qué sos la mejor opción…')),
                const SizedBox(height: 22),
                AppButton(label: 'Enviar oferta', icon: Icons.send_rounded, loading: _busy, onPressed: () => _send(r)),
              ],
            ]),
    );
  }
}

// ============================================================ TRABAJOS (técnico)
class TechJobsTab extends ConsumerStatefulWidget {
  const TechJobsTab({super.key});
  @override
  ConsumerState<TechJobsTab> createState() => _TechJobsTabState();
}

class _TechJobsTabState extends ConsumerState<TechJobsTab> {
  bool _history = false;
  @override
  Widget build(BuildContext context) {
    final res = ref.watch(jobsProvider('tech'));
    return SafeArea(
      bottom: false,
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 12, 8, 4), child: Row(children: [Expanded(child: Text('Mis trabajos', style: context.tt.headlineSmall)), const BellButton()])),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [ButtonSegment(value: false, label: Text('Activos')), ButtonSegment(value: true, label: Text('Historial'))],
            selected: {_history},
            onSelectionChanged: (s) => setState(() => _history = s.first),
          ),
        ),
        Expanded(
          child: AsyncBody<List<Job>>(
            value: res,
            onRetry: () async => ref.refresh(jobsProvider('tech').future),
            builder: (all) {
              final items = all.where((j) => _history ? !j.isActive : j.isActive).toList();
              if (items.isEmpty) {
                return EmptyState(icon: _history ? Icons.history_rounded : Icons.handyman_rounded, title: _history ? 'Sin historial todavía' : 'No tenés trabajos activos', message: _history ? 'Tus trabajos completados van a aparecer acá.' : 'Cuando un cliente acepte tu oferta o reserve un servicio, lo ves acá.');
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (c, i) => JobCard(job: items[i], clientView: false, onTap: () => context.push('/job/${items[i].id}')),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ============================================================ MIS OFERTAS
class MyOffersScreen extends ConsumerWidget {
  const MyOffersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final res = ref.watch(myOffersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis ofertas')),
      body: AsyncBody<List<Offer>>(
        value: res,
        onRetry: () async => ref.refresh(myOffersProvider.future),
        builder: (items) {
          if (items.isEmpty) {
            return EmptyState(icon: Icons.local_offer_outlined, title: 'Todavía no ofertaste', message: 'Mirá las necesidades cerca tuyo y mandá tu primera oferta.', actionLabel: 'Ver oportunidades', onAction: () {
              ref.read(techTabProvider.notifier).state = 1;
              context.go('/home');
            });
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (c, i) {
              final o = items[i];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(rLg),
                  onTap: () => context.push('/opportunity/${o.requestId}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Expanded(child: Text(o.requestTitle ?? 'Necesidad', maxLines: 2, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium)), StatusPill(o.status)]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Text(money(o.price), style: context.tt.titleLarge?.copyWith(color: context.cs.primary)),
                        const SizedBox(width: 10),
                        Text('· recibís ${money(techNetOf(o.price))}', style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 13)),
                      ]),
                      const SizedBox(height: 4),
                      Text('Llegás ${fmtEta(o.etaMinutes)} · dura ${fmtMinutes(o.durationMinutes)} · ${timeAgo(o.createdAt)}', style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 12.5)),
                      if (o.status == 'pending')
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () async {
                              final ok = await confirmDialog(context, title: '¿Retirar la oferta?', message: 'El cliente ya no la va a ver.', confirm: 'Retirar', danger: true);
                              if (!ok) return;
                              try {
                                await ref.read(apiProvider).withdrawOffer(o.id);
                                ref.invalidate(myOffersProvider);
                                if (context.mounted) showSnack(context, 'Oferta retirada', ok: true);
                              } catch (e) {
                                if (context.mounted) showSnack(context, errorText(e), error: true);
                              }
                            },
                            child: const Text('Retirar oferta', style: TextStyle(color: FixiColors.error)),
                          ),
                        ),
                    ]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================ MIS SERVICIOS
class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final res = ref.watch(myListingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis servicios')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => context.push('/listing-edit'), icon: const Icon(Icons.add_rounded), label: const Text('Nuevo servicio')),
      body: AsyncBody<List<Listing>>(
        value: res,
        onRetry: () async => ref.refresh(myListingsProvider.future),
        builder: (items) {
          if (items.isEmpty) {
            return EmptyState(icon: Icons.storefront_rounded, title: 'Publicá tu primer servicio', message: 'Los clientes te pueden reservar directo, con precio claro y sin esperar ofertas.', actionLabel: 'Crear servicio', onAction: () => context.push('/listing-edit'));
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (c, i) {
              final l = items[i];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(rLg),
                  onTap: () => context.push('/listing-edit', extra: l),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l.title, style: context.tt.titleMedium),
                        const SizedBox(height: 4),
                        Text('${l.pricePrefix}${money(l.price)}${l.priceSuffix} · ${fmtMinutes(l.durationMinutes)}', style: TextStyle(color: context.cs.primary, fontWeight: FontWeight.w800)),
                        Text(l.active ? 'Visible para clientes' : 'Pausado', style: TextStyle(fontSize: 12.5, color: context.cs.onSurfaceVariant)),
                      ])),
                      Switch.adaptive(
                        value: l.active,
                        onChanged: (v) async {
                          try {
                            await ref.read(apiProvider).updateListing(l.id, {'active': v});
                            ref.invalidate(myListingsProvider);
                          } catch (e) {
                            if (context.mounted) showSnack(context, errorText(e), error: true);
                          }
                        },
                      ),
                    ]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ListingEditScreen extends ConsumerStatefulWidget {
  const ListingEditScreen({super.key, this.listing});
  final Listing? listing;
  @override
  ConsumerState<ListingEditScreen> createState() => _ListingEditScreenState();
}

class _ListingEditScreenState extends ConsumerState<ListingEditScreen> {
  late final _title = TextEditingController(text: widget.listing?.title ?? '');
  late final _desc = TextEditingController(text: widget.listing?.description ?? '');
  late final _price = TextEditingController(text: widget.listing == null ? '' : '${widget.listing!.price}');
  late String? _cat = widget.listing?.categoryId;
  late String _type = widget.listing?.priceType ?? 'fixed';
  late int _dur = widget.listing?.durationMinutes ?? 60;
  late bool _active = widget.listing?.active ?? true;
  bool _busy = false;
  final _form = GlobalKey<FormState>();

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_cat == null) {
      showSnack(context, 'Elegí una categoría', error: true);
      return;
    }
    setState(() => _busy = true);
    final body = {'categoryId': _cat, 'title': _title.text.trim(), 'description': _desc.text.trim(), 'price': int.parse(_price.text), 'priceType': _type, 'durationMinutes': _dur, 'active': _active};
    try {
      if (widget.listing == null) {
        await ref.read(apiProvider).createListing(body);
      } else {
        await ref.read(apiProvider).updateListing(widget.listing!.id, body);
      }
      ref.invalidate(myListingsProvider);
      success();
      if (mounted) {
        showSnack(context, 'Servicio guardado', ok: true);
        context.pop();
      }
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(context, title: '¿Eliminar este servicio?', message: 'Dejará de aparecer para los clientes.', confirm: 'Eliminar', danger: true);
    if (!ok) return;
    try {
      await ref.read(apiProvider).deleteListing(widget.listing!.id);
      ref.invalidate(myListingsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final mine = ref.watch(authProvider).tech?.categoryIds ?? [];
    final avail = mine.isEmpty ? cats : cats.where((c) => mine.contains(c.id) || c.id == _cat).toList();
    final price = int.tryParse(_price.text);
    return Scaffold(
      appBar: AppBar(title: Text(widget.listing == null ? 'Nuevo servicio' : 'Editar servicio'), actions: [if (widget.listing != null) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded, color: FixiColors.error))]),
      body: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), children: [
          DropdownButtonFormField<String>(
            value: avail.any((c) => c.id == _cat) ? _cat : null,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: [for (final c in avail) DropdownMenuItem(value: c.id, child: Text(c.name))],
            onChanged: (v) => setState(() => _cat = v),
          ),
          const SizedBox(height: 14),
          TextFormField(controller: _title, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Título', hintText: 'Ej: Service de aire acondicionado split'), validator: (v) => (v ?? '').trim().length < 4 ? 'Poné un título claro' : null),
          const SizedBox(height: 14),
          TextFormField(controller: _desc, minLines: 3, maxLines: 6, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Qué incluye', alignLabelWithHint: true)),
          const SizedBox(height: 18),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [ButtonSegment(value: 'fixed', label: Text('Precio fijo')), ButtonSegment(value: 'from', label: Text('Desde')), ButtonSegment(value: 'hourly', label: Text('Por hora'))],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$ '),
            validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Poné un precio' : null,
          ),
          if (price != null && price > 0) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Recibís ${money(techNetOf(price))} después de la comisión de ${AppConst.commissionPercent}%', style: const TextStyle(color: FixiColors.success, fontWeight: FontWeight.w700))),
          const SizedBox(height: 18),
          Text('Duración estimada', style: context.tt.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final v in [30, 60, 90, 120, 180, 240]) ChoiceChip(label: Text(fmtMinutes(v)), selected: _dur == v, onSelected: (_) => setState(() => _dur = v))]),
          const SizedBox(height: 10),
          SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, value: _active, onChanged: (v) => setState(() => _active = v), title: const Text('Visible para clientes', style: TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(height: 14),
          AppButton(label: 'Guardar servicio', loading: _busy, onPressed: _save),
        ]),
      ),
    );
  }
}

// ============================================================ ALTA / EDICIÓN DE PERFIL TÉCNICO
class TechSetupScreen extends ConsumerStatefulWidget {
  const TechSetupScreen({super.key});
  @override
  ConsumerState<TechSetupScreen> createState() => _TechSetupScreenState();
}

class _TechSetupScreenState extends ConsumerState<TechSetupScreen> {
  late final TechProfile? _p = ref.read(authProvider).tech;
  late final _bio = TextEditingController(text: _p?.bio ?? '');
  late final Set<String> _cats = {...?_p?.categoryIds};
  late double _radius = _p?.radiusKm ?? 10;
  late bool _avail = _p?.available ?? true;
  bool _busy = false;

  Future<void> _save() async {
    if (_cats.isEmpty) {
      showSnack(context, 'Elegí al menos una categoría', error: true);
      return;
    }
    if (_bio.text.trim().length < 10) {
      showSnack(context, 'Contá un poco sobre vos y tu experiencia (mínimo 10 letras)', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final creating = _p == null;
      await ref.read(apiProvider).putTechProfile({'bio': _bio.text.trim(), 'categoryIds': _cats.toList(), 'radiusKm': _radius.round(), 'available': _avail});
      await ref.read(authProvider.notifier).refresh();
      if (creating) ref.read(settingsProvider.notifier).setMode('tech');
      success();
      if (!mounted) return;
      showSnack(context, creating ? '¡Listo! Ya sos técnico en Fixi.' : 'Perfil actualizado', ok: true);
      context.pop();
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(_p == null ? 'Ofrecé tus servicios' : 'Perfil técnico')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), children: [
        if (_p == null) Padding(padding: const EdgeInsets.only(bottom: 18), child: Text('Armá tu perfil en un minuto y empezá a recibir oportunidades cerca tuyo. Fixi cobra ${AppConst.commissionPercent}% solo cuando cobrás.', style: TextStyle(color: context.cs.onSurfaceVariant, height: 1.45))),
        TextField(controller: _bio, minLines: 4, maxLines: 7, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Sobre vos', hintText: 'Años de experiencia, especialidades, herramientas…', alignLabelWithHint: true)),
        const SizedBox(height: 22),
        Text('¿Qué servicios ofrecés?', style: context.tt.titleMedium),
        const SizedBox(height: 10),
        cats.when(
          loading: () => const Skeleton(height: 140, radius: 16),
          error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(categoriesProvider)),
          data: (list) => Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in list)
              FilterChip(
                avatar: Icon(categoryIcon(c.icon), size: 18),
                showCheckmark: false,
                label: Text(c.name),
                selected: _cats.contains(c.id),
                onSelected: (v) {
                  tap();
                  setState(() => v ? _cats.add(c.id) : _cats.remove(c.id));
                },
              ),
          ]),
        ),
        const SizedBox(height: 24),
        Row(children: [Text('Radio de trabajo', style: context.tt.titleMedium), const Spacer(), Text('${_radius.round()} km', style: TextStyle(fontWeight: FontWeight.w800, color: context.cs.primary, fontSize: 16))]),
        Slider(value: _radius, min: 1, max: 50, divisions: 49, label: '${_radius.round()} km', onChanged: (v) => setState(() => _radius = v)),
        SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, value: _avail, onChanged: (v) => setState(() => _avail = v), title: const Text('Disponible para trabajar', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('Podés cambiarlo cuando quieras desde el panel.')),
        const SizedBox(height: 20),
        AppButton(label: _p == null ? 'Crear perfil técnico' : 'Guardar cambios', loading: _busy, onPressed: _save),
      ]),
    );
  }
}
