import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/realtime.dart';
import '../../core/models/models.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/format.dart';
import '../../core/widgets/common.dart';
import '../shared/cards.dart';

/// Si el servidor devuelve un checkout con localhost, lo reemplazamos por el host configurado en la app.
String fixCheckoutUrl(String url, String baseUrl) {
  final u = Uri.tryParse(url);
  final b = Uri.tryParse(baseUrl);
  if (u == null || b == null) return url;
  if (!u.hasScheme) return Uri.parse(baseUrl).resolve(url).toString();
  if (const ['localhost', '127.0.0.1', '10.0.2.2', '0.0.0.0'].contains(u.host) && u.host != b.host) {
    return u.replace(scheme: b.scheme, host: b.host, port: b.hasPort ? b.port : null).toString();
  }
  return url;
}

// ============================================================ CELEBRACIÓN
class Celebration extends StatelessWidget {
  const Celebration({super.key, this.size = 160});
  final double size;
  @override
  Widget build(BuildContext context) {
    final rnd = math.Random(7);
    const colors = [FixiColors.lime, FixiColors.primary, FixiColors.warning, FixiColors.success, Color(0xFF8A4DFF)];
    return SizedBox(
      width: size * 2,
      height: size * 2,
      child: Stack(alignment: Alignment.center, children: [
        for (var i = 0; i < 28; i++)
          () {
            final a = rnd.nextDouble() * math.pi * 2;
            final d = size * (.7 + rnd.nextDouble() * .9);
            return Container(
              width: 8 + rnd.nextDouble() * 6,
              height: 8 + rnd.nextDouble() * 6,
              decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(rnd.nextBool() ? 99 : 3)),
            ).animate(delay: (200 + rnd.nextInt(250)).ms).move(begin: Offset.zero, end: Offset(math.cos(a) * d, math.sin(a) * d), duration: 900.ms, curve: Curves.easeOutCubic).rotate(end: rnd.nextDouble() * 2).fadeOut(delay: 700.ms, duration: 400.ms);
          }(),
        Container(
          width: size * .8,
          height: size * .8,
          decoration: const BoxDecoration(color: FixiColors.success, shape: BoxShape.circle),
          child: Icon(Icons.check_rounded, color: Colors.white, size: size * .5),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut).fadeIn(duration: 200.ms),
      ]),
    );
  }
}

// ============================================================ PAGO
class PayScreen extends ConsumerStatefulWidget {
  const PayScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends ConsumerState<PayScreen> with WidgetsBindingObserver {
  bool _busy = false, _waiting = false, _paid = false;
  Timer? _poll;
  int _polls = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed && _waiting) _check();
  }

  bool _isPaid(Job j) => j.status != 'pending_payment' && j.status != 'cancelled' || j.paymentStatus == 'held' || j.paymentStatus == 'released';

  Future<void> _check() async {
    try {
      final j = await ref.read(apiProvider).job(widget.id);
      if (_isPaid(j)) _onPaid();
    } catch (_) {}
  }

  void _onPaid() {
    if (_paid || !mounted) return;
    _poll?.cancel();
    success();
    ref.invalidate(jobProvider(widget.id));
    ref.invalidate(jobsProvider);
    setState(() {
      _paid = true;
      _waiting = false;
    });
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) context.pushReplacement('/job/${widget.id}');
    });
  }

  Future<void> _pay() async {
    setState(() => _busy = true);
    try {
      final (p, url) = await ref.read(apiProvider).pay(widget.id);
      if (url == null) throw const ApiException('NO_URL', 'El servidor no devolvió el link de pago.');
      final fixed = fixCheckoutUrl(url, ref.read(settingsProvider).baseUrl);
      final ok = await launchUrl(Uri.parse(fixed), mode: LaunchMode.externalApplication);
      if (!ok) throw const ApiException('LAUNCH', 'No pudimos abrir el navegador para pagar.');
      setState(() => _waiting = true);
      _polls = 0;
      _poll?.cancel();
      _poll = Timer.periodic(const Duration(seconds: 3), (_) {
        if (++_polls > 200) _poll?.cancel();
        _check();
      });
      if (p != null) debugPrint('Pago ${p.id} (${p.provider}) iniciado');
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Job>>(jobProvider(widget.id), (_, n) {
      final j = n.valueOrNull;
      if (j != null && _waiting && _isPaid(j)) _onPaid();
    });
    final res = ref.watch(jobProvider(widget.id));
    final cs = context.cs;
    if (_paid) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Celebration(),
            const SizedBox(height: 8),
            Text('¡Pago confirmado!', style: context.tt.headlineMedium).animate(delay: 400.ms).fadeIn().slideY(begin: .3),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text('Tu dinero queda protegido hasta que confirmes el trabajo. Ya avisamos al técnico.', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant, height: 1.4)).animate(delay: 600.ms).fadeIn(),
            ),
          ]),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar y pagar')),
      body: AsyncBody<Job>(
        value: res,
        onRetry: () async => ref.refresh(jobProvider(widget.id).future),
        builder: (j) {
          if (_isPaid(j) && !_waiting) {
            return EmptyState(icon: Icons.verified_rounded, title: 'Este trabajo ya está pago', message: 'Podés seguir su avance desde la pantalla del trabajo.', actionLabel: 'Ver trabajo', onAction: () => context.pushReplacement('/job/${j.id}'));
          }
          return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    FixiAvatar(url: j.tech?.avatarUrl, name: j.tech?.name ?? '?', size: 52),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(j.tech?.name ?? 'Técnico', style: context.tt.titleMedium), if (j.tech != null) Padding(padding: const EdgeInsets.only(top: 4), child: Wrap(spacing: 8, children: [RatingChip(j.tech!.ratingAvg, j.tech!.ratingCount), LevelBadge(j.tech!.level, compact: true)]))])),
                  ]),
                  const Divider(height: 28),
                  Text(j.title, style: context.tt.titleMedium),
                  const SizedBox(height: 6),
                  Row(children: [Icon(Icons.location_on_outlined, size: 16, color: cs.onSurfaceVariant), const SizedBox(width: 4), Expanded(child: Text(j.address, style: TextStyle(color: cs.onSurfaceVariant)))]),
                  const SizedBox(height: 4),
                  Row(children: [Icon(Icons.schedule_rounded, size: 16, color: cs.onSurfaceVariant), const SizedBox(width: 4), Text('Llega ${fmtEta(j.etaMinutes)}', style: TextStyle(color: cs.onSurfaceVariant))]),
                  const Divider(height: 28),
                  Row(children: [const Expanded(child: Text('Servicio', style: TextStyle(fontWeight: FontWeight.w600))), Text(money(j.price))]),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Expanded(child: Text('Pagás', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
                    Text(money(j.price), style: context.tt.headlineSmall?.copyWith(color: cs.primary)),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: FixiColors.success.withOpacity(.1), borderRadius: BorderRadius.circular(rLg)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Row(children: [Icon(Icons.shield_rounded, color: FixiColors.success), SizedBox(width: 10), Text('Pago protegido', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))]),
                SizedBox(height: 8),
                Text('El pago se libera cuando confirmás el trabajo. Si algo sale mal, podés reportar el problema y lo revisamos.', style: TextStyle(height: 1.4)),
              ]),
            ),
            const SizedBox(height: 24),
            if (_waiting) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(rLg)),
                child: Row(children: [
                  const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
                  const SizedBox(width: 14),
                  const Expanded(child: Text('Esperando la confirmación del pago… Cuando termines en el navegador, volvé a Fixi.', style: TextStyle(height: 1.35, fontWeight: FontWeight.w600))),
                ]),
              ).animate().fadeIn(),
              const SizedBox(height: 14),
              AppButton(label: 'Ya pagué, verificar', outlined: true, icon: Icons.refresh_rounded, onPressed: () async {
                await _check();
                if (!_paid && mounted) showSnack(context, 'Todavía no vemos el pago. Probá en unos segundos.');
              }),
              const SizedBox(height: 10),
              TextButton(onPressed: _pay, child: const Text('Volver a abrir el pago')),
            ] else
              AppButton(label: 'Pagar ${money(j.price)}', icon: Icons.lock_rounded, loading: _busy, onPressed: _pay),
            const SizedBox(height: 12),
            Center(child: Text('Vas a completar el pago de forma segura en tu navegador.', style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant))),
          ]);
        },
      ),
    );
  }
}

// ============================================================ SEGUIMIENTO DEL TRABAJO
class JobScreen extends ConsumerStatefulWidget {
  const JobScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends ConsumerState<JobScreen> {
  bool _busy = false;
  final _map = MapController();

  static const _steps = ['Pago confirmado', 'Técnico en camino', 'Trabajo en curso', 'Trabajo terminado', 'Confirmado por vos'];
  static const _stepsTech = ['Pago confirmado', 'Estoy en camino', 'Trabajo en curso', 'Marqué terminado', 'Cliente confirmó'];

  int _stage(String s) => switch (s) { 'paid' => 0, 'on_the_way' => 1, 'in_progress' => 2, 'done' => 3, 'completed' => 4, _ => -1 };

  Future<void> _act(String status, {String? okMsg}) async {
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).setStatus(widget.id, status);
      ref.invalidate(jobProvider(widget.id));
      ref.invalidate(jobsProvider);
      ref.invalidate(earningsProvider);
      success();
      if (okMsg != null && mounted) showSnack(context, okMsg, ok: true);
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDone(Job j) async {
    final ok = await confirmDialog(context, title: '¿El trabajo quedó bien?', message: 'Al confirmar, liberamos ${money(j.price)} al técnico. Esta acción no se puede deshacer.', confirm: 'Sí, confirmar');
    if (!ok) return;
    await _act('completed');
    if (mounted) _review(j);
  }

  Future<void> _dispute(Job j) async {
    final c = TextEditingController();
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Reportar un problema', style: context.tt.titleLarge),
          const SizedBox(height: 6),
          Text('Contanos qué pasó. Frenamos el pago y el equipo de Fixi revisa el caso.', style: TextStyle(color: context.cs.onSurfaceVariant, height: 1.4)),
          const SizedBox(height: 16),
          TextField(controller: c, minLines: 3, maxLines: 5, decoration: const InputDecoration(hintText: 'Ej: el equipo sigue sin funcionar…')),
          const SizedBox(height: 16),
          AppButton(label: 'Enviar reporte', color: FixiColors.error, onPressed: () => Navigator.pop(ctx, c.text.trim())),
        ]),
      ),
    );
    if (reason == null) return;
    try {
      if (reason.isNotEmpty) await ref.read(apiProvider).sendMessage(j.id, 'Reporte de problema: $reason');
    } catch (_) {}
    await _act('disputed', okMsg: 'Recibimos tu reporte. Te avisamos cuando lo revisemos.');
  }

  Future<void> _review(Job j) async {
    final done = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (c) => _ReviewSheet(job: j));
    if (done == true) {
      ref.invalidate(jobProvider(j.id));
      ref.invalidate(techPublicProvider);
      if (mounted) showSnack(context, '¡Gracias por tu calificación!', ok: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = ref.watch(jobProvider(widget.id));
    final me = ref.watch(authProvider).user;
    final cs = context.cs;
    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento')),
      body: AsyncBody<Job>(
        value: res,
        onRetry: () async => ref.refresh(jobProvider(widget.id).future),
        builder: (j) {
          final isClient = me?.id == j.clientId;
          final stage = _stage(j.status);
          final live = ref.watch(liveLocationProvider(j.id));
          final other = isClient ? (j.tech == null ? null : (j.tech!.name, j.tech!.avatarUrl)) : (j.client == null ? null : (j.client!.name, j.client!.avatarUrl));
          final hasPlace = j.lat != 0 || j.lng != 0;
          final dest = LatLng(j.lat, j.lng);
          final showMap = hasPlace && j.isPaid && j.status != 'cancelled' && j.status != 'completed';
          return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 40), children: [
            Row(children: [Expanded(child: Text(j.title, style: context.tt.headlineSmall)), const SizedBox(width: 8), StatusPill(j.status)]),
            const SizedBox(height: 6),
            Row(children: [Icon(Icons.location_on_outlined, size: 16, color: cs.onSurfaceVariant), const SizedBox(width: 4), Expanded(child: Text(j.address, style: TextStyle(color: cs.onSurfaceVariant)))]),
            const SizedBox(height: 18),
            if (j.status == 'pending_payment' && isClient)
              GradientCard(
                onTap: () => context.push('/job/${j.id}/pay'),
                colors: const [Color(0xFFFFB020), Color(0xFFFF7A3C)],
                child: Row(children: [
                  const Icon(Icons.payments_rounded, color: Colors.white, size: 30),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Falta pagar para confirmar al técnico', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
                  Text(money(j.price), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                ]),
              ),
            if (j.status == 'disputed')
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: FixiColors.error.withOpacity(.1), borderRadius: BorderRadius.circular(rMd)),
                child: const Row(children: [Icon(Icons.gavel_rounded, color: FixiColors.error), SizedBox(width: 10), Expanded(child: Text('Este trabajo está en revisión. El pago queda retenido hasta que Fixi lo resuelva.', style: TextStyle(height: 1.35, fontWeight: FontWeight.w600)))]),
              ),
            if (showMap) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(rXl),
                child: SizedBox(
                  height: 210,
                  child: FixiMap(
                    center: live ?? dest,
                    zoom: 14.5,
                    controller: _map,
                    markers: [
                      pinMarker(dest, Icons.home_rounded, FixiColors.primary),
                      if (live != null) pinMarker(live, Icons.directions_car_filled_rounded, FixiColors.success, size: 50),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  live != null ? 'Ubicación del técnico en vivo' : (j.status == 'on_the_way' && isClient ? 'Esperando la ubicación del técnico…' : 'Destino del servicio'),
                  style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(children: [
                  for (var i = 0; i < 5; i++) _TimelineRow(label: (isClient ? _steps : _stepsTech)[i], done: stage >= i, current: stage == i, last: i == 4, time: _timeFor(j, i)),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            if (other != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    FixiAvatar(url: other.$2, name: other.$1, size: 52, heroTag: isClient ? 'tech-${j.techId}' : null),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(other.$1, style: context.tt.titleMedium),
                      if (isClient && j.tech != null) Padding(padding: const EdgeInsets.only(top: 4), child: Wrap(spacing: 8, children: [RatingChip(j.tech!.ratingAvg, j.tech!.ratingCount), LevelBadge(j.tech!.level, compact: true)])),
                      if (!isClient) Text('Cliente', style: TextStyle(color: cs.onSurfaceVariant)),
                    ])),
                    if (isClient) IconButton.outlined(onPressed: () => context.push('/t/${j.techId}'), icon: const Icon(Icons.person_search_rounded), tooltip: 'Ver perfil'),
                    const SizedBox(width: 6),
                    IconButton.filled(
                      onPressed: j.status == 'pending_payment' && isClient ? null : () => context.push('/job/${j.id}/chat', extra: other.$1),
                      icon: const Icon(Icons.chat_bubble_rounded),
                      tooltip: 'Chat',
                    ),
                  ]),
                ),
              ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(children: [
                  _line('Precio del servicio', money(j.price)),
                  if (!isClient) ...[
                    _line('Comisión Fixi (5%)', '- ${money(j.commission)}', muted: true),
                    const Divider(height: 22),
                    _line('Vas a recibir', money(j.techNet), bold: true, color: FixiColors.success),
                  ] else ...[
                    const Divider(height: 22),
                    _line('Pagás', money(j.price), bold: true),
                    _line('Estado del pago', _payLabel(j.paymentStatus), muted: true),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: 20),
            ..._actions(j, isClient),
          ]);
        },
      ),
    );
  }

  String _payLabel(String s) => switch (s) { 'held' => 'Protegido hasta que confirmes', 'released' => 'Liberado al técnico', 'refunded' => 'Reembolsado', _ => 'Pendiente' };

  DateTime? _timeFor(Job j, int i) => switch (i) { 0 => j.paidAt, 2 => j.startedAt, 4 => j.completedAt, _ => null };

  Widget _line(String a, String b, {bool bold = false, bool muted = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(a, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: muted ? context.cs.onSurfaceVariant : null))),
          Text(b, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w700, fontSize: bold ? 18 : 14.5, color: color ?? (muted ? context.cs.onSurfaceVariant : null))),
        ]),
      );

  List<Widget> _actions(Job j, bool isClient) {
    final w = <Widget>[];
    void add(Widget x) => w..add(x)..add(const SizedBox(height: 10));
    if (isClient) {
      if (j.status == 'pending_payment') add(AppButton(label: 'Pagar ahora', icon: Icons.lock_rounded, onPressed: () => context.push('/job/${j.id}/pay')));
      if (j.status == 'done') add(AppButton(label: 'Confirmar trabajo terminado', icon: Icons.verified_rounded, loading: _busy, onPressed: () => _confirmDone(j)));
      if (j.status == 'completed' && j.myReview == null) add(AppButton(label: 'Calificar al técnico', icon: Icons.star_rounded, onPressed: () => _review(j)));
    } else {
      if (j.status == 'paid') add(AppButton(label: 'Estoy en camino', icon: Icons.directions_run_rounded, loading: _busy, onPressed: () => _act('on_the_way', okMsg: 'Avisamos al cliente. Vamos compartiendo tu ubicación.')));
      if (j.status == 'on_the_way') add(AppButton(label: 'Empecé el trabajo', icon: Icons.play_arrow_rounded, loading: _busy, onPressed: () => _act('in_progress')));
      if (j.status == 'in_progress') add(AppButton(label: 'Terminé el trabajo', icon: Icons.task_alt_rounded, loading: _busy, onPressed: () => _act('done', okMsg: 'Avisamos al cliente para que confirme.')));
      if (j.status == 'done') add(Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: context.cs.primaryContainer, borderRadius: BorderRadius.circular(rMd)), child: const Row(children: [Icon(Icons.hourglass_top_rounded), SizedBox(width: 10), Expanded(child: Text('Esperando que el cliente confirme para liberar tu pago.', style: TextStyle(fontWeight: FontWeight.w600)))])));
      if (j.status == 'completed' && j.myReview == null) add(AppButton(label: 'Calificar al cliente', icon: Icons.star_rounded, outlined: true, onPressed: () => _review(j)));
    }
    if (j.myReview != null) {
      add(Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [StarsRow(j.myReview!.rating), const SizedBox(width: 12), Expanded(child: Text(j.myReview!.comment.isEmpty ? 'Tu calificación' : j.myReview!.comment, maxLines: 2, overflow: TextOverflow.ellipsis))]))));
    }
    if (const ['paid', 'on_the_way'].contains(j.status) || (j.status == 'pending_payment' && isClient)) {
      add(TextButton(
        onPressed: _busy
            ? null
            : () async {
                final ok = await confirmDialog(context, title: '¿Cancelar el trabajo?', message: j.isPaid ? 'Se reembolsa el pago según corresponda.' : 'Todavía no pagaste, así que no hay cargo.', confirm: 'Cancelar trabajo', cancel: 'Volver', danger: true);
                if (ok) _act('cancelled', okMsg: 'Trabajo cancelado');
              },
        child: const Text('Cancelar trabajo', style: TextStyle(color: FixiColors.error)),
      ));
    }
    if (j.status == 'in_progress' || j.status == 'done') {
      add(TextButton.icon(onPressed: () => _dispute(j), icon: const Icon(Icons.report_gmailerrorred_rounded, color: FixiColors.error), label: const Text('Reportar un problema', style: TextStyle(color: FixiColors.error))));
    }
    return w;
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.label, required this.done, required this.current, required this.last, this.time});
  final String label;
  final bool done, current, last;
  final DateTime? time;
  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final color = done ? FixiColors.success : cs.outline;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 28,
          child: Column(children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: done ? FixiColors.success : Colors.transparent, shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
              child: done ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
            ).animate(target: current ? 1 : 0, onPlay: (c) => current ? c.repeat(reverse: true) : null).scale(end: const Offset(1.15, 1.15), duration: 800.ms),
            if (!last) Expanded(child: Container(width: 2, color: done ? FixiColors.success : cs.outlineVariant)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(children: [
              Expanded(child: Text(label, style: TextStyle(fontWeight: current ? FontWeight.w800 : FontWeight.w600, color: done ? null : cs.onSurfaceVariant))),
              if (time != null) Text(fmtClock(time), style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({required this.job});
  final Job job;
  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  int _rating = 5;
  final _c = TextEditingController();
  bool _busy = false;

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).review(widget.job.id, _rating, _c.text.trim());
      success();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['', 'Muy malo', 'Podría mejorar', 'Estuvo bien', 'Muy bueno', '¡Excelente!'];
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('¿Cómo te fue?', style: context.tt.titleLarge),
          const SizedBox(height: 8),
          StarPicker(value: _rating, onChanged: (v) => setState(() => _rating = v)),
          Text(labels[_rating], style: TextStyle(fontWeight: FontWeight.w800, color: context.cs.primary, fontSize: 16)),
          const SizedBox(height: 16),
          TextField(controller: _c, minLines: 2, maxLines: 4, decoration: const InputDecoration(hintText: 'Dejá un comentario (opcional)')),
          const SizedBox(height: 18),
          AppButton(label: 'Enviar calificación', loading: _busy, onPressed: _send),
        ]),
      ),
    );
  }
}

// ============================================================ CHAT
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.jobId, this.title});
  final String jobId;
  final String? title;
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _c = TextEditingController();
  List<ChatMessage> _msgs = [];
  Object? _error;
  bool _loading = true, _sending = false;
  late final ProviderContainer _container;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context);
    Future.microtask(() => _container.read(activeChatProvider.notifier).state = widget.jobId);
  }

  @override
  void dispose() {
    final c = _container;
    Future.microtask(() => c.read(activeChatProvider.notifier).state = null);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final l = await ref.read(apiProvider).messages(widget.jobId);
      if (mounted) setState(() {
        _msgs = l;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    final t = _c.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    _c.clear();
    tap();
    try {
      final m = await ref.read(apiProvider).sendMessage(widget.jobId, t);
      if (mounted && !_msgs.any((x) => x.id == m.id)) setState(() => _msgs = [..._msgs, m]);
    } catch (e) {
      _c.text = t;
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authProvider).user;
    final cs = context.cs;
    ref.listen<AsyncValue<WsEvent>>(wsEventsProvider, (_, n) {
      final ev = n.valueOrNull;
      if (ev == null || ev.type != 'message.new') return;
      final m = ChatMessage.fromJson(asMap(ev.data['message'] ?? ev.data));
      if (m.jobId == widget.jobId && !_msgs.any((x) => x.id == m.id)) setState(() => _msgs = [..._msgs, m]);
    });
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Chat')),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const SkeletonList(count: 3)
              : _error != null
                  ? ErrorState(error: _error!, onRetry: () {
                      setState(() => _loading = true);
                      _load();
                    })
                  : _msgs.isEmpty
                      ? const EmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'Todavía no hay mensajes', message: 'Coordiná los detalles con tu técnico o cliente. Todo queda guardado en el trabajo.')
                      : ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: _msgs.length,
                          itemBuilder: (c, i) {
                            final m = _msgs[_msgs.length - 1 - i];
                            final mine = m.fromUserId == me?.id;
                            return Align(
                              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: mine ? cs.primary : cs.surface,
                                  border: mine ? null : Border.all(color: cs.outlineVariant),
                                  borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(mine ? 18 : 4), bottomRight: Radius.circular(mine ? 4 : 18)),
                                ),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                                  Text(m.text, style: TextStyle(color: mine ? cs.onPrimary : cs.onSurface, height: 1.3, fontSize: 15)),
                                  const SizedBox(height: 3),
                                  Text(fmtClock(m.createdAt), style: TextStyle(fontSize: 10.5, color: (mine ? cs.onPrimary : cs.onSurfaceVariant).withOpacity(.75))),
                                ]),
                              ).animate().fadeIn(duration: 200.ms).slideY(begin: .1),
                            );
                          },
                        ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(color: cs.surface, border: Border(top: BorderSide(color: cs.outlineVariant))),
            child: Row(children: [
              Expanded(child: TextField(controller: _c, minLines: 1, maxLines: 4, textCapitalization: TextCapitalization.sentences, onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'Escribí un mensaje…', contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12)))),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _send, icon: const Icon(Icons.send_rounded), style: IconButton.styleFrom(minimumSize: const Size(50, 50))),
            ]),
          ),
        ),
      ]),
    );
  }
}
