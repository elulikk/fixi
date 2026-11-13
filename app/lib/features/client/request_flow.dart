import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_client.dart';
import '../../core/config/constants.dart';
import '../../core/models/models.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/format.dart';
import '../../core/widgets/common.dart';
import '../shared/cards.dart';

// ============================================================ PUBLICAR NECESIDAD (flujo en pasos)
class RequestFlowScreen extends ConsumerStatefulWidget {
  const RequestFlowScreen({super.key});
  @override
  ConsumerState<RequestFlowScreen> createState() => _RequestFlowScreenState();
}

class _RequestFlowScreenState extends ConsumerState<RequestFlowScreen> {
  static const _titles = ['¿Qué tipo de servicio?', 'Contanos qué pasa', '¿Dónde y cuándo?', 'Presupuesto', 'Revisá y publicá'];
  int _step = 0;
  String? _cat;
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _addr = TextEditingController();
  final _budget = TextEditingController();
  final List<String> _photos = [];
  String _urgency = 'today';
  DateTime? _when;
  double? _lat, _lng;
  int _uploading = 0;
  bool _busy = false, _restored = false;


  @override
  void initState() {
    super.initState();
    _restore();
    for (final c in [_title, _desc, _addr, _budget]) {
      c.addListener(_save);
    }
  }

  void _restore() {
    final raw = ref.read(prefsProvider).getString('requestDraft');
    final u = ref.read(authProvider).user;
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        _cat = j['cat'] as String?;
        _title.text = j['title'] ?? '';
        _desc.text = j['desc'] ?? '';
        _addr.text = j['addr'] ?? '';
        _budget.text = j['budget'] ?? '';
        _photos.addAll(((j['photos'] as List?) ?? []).map((e) => '$e'));
        _urgency = j['urgency'] ?? 'today';
        _when = j['when'] == null ? null : DateTime.tryParse(j['when']);
        _lat = (j['lat'] as num?)?.toDouble();
        _lng = (j['lng'] as num?)?.toDouble();
        _step = (j['step'] as int?) ?? 0;
        _restored = _cat != null || _title.text.isNotEmpty;
      } catch (_) {}
    }
    if (_addr.text.isEmpty) _addr.text = u?.address ?? '';
    if (_restored) {
      WidgetsBinding.instance.addPostFrameCallback((_) => showSnack(context, 'Retomamos tu borrador. Seguí desde donde quedaste.'));
    }
  }

  void _save() {
    ref.read(prefsProvider).setString(
        'requestDraft',
        jsonEncode({
          'cat': _cat,
          'title': _title.text,
          'desc': _desc.text,
          'addr': _addr.text,
          'budget': _budget.text,
          'photos': _photos,
          'urgency': _urgency,
          'when': _when?.toIso8601String(),
          'lat': _lat,
          'lng': _lng,
          'step': _step,
        }));
  }

  @override
  void dispose() {
    for (final c in [_title, _desc, _addr, _budget]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid {
    switch (_step) {
      case 0:
        return _cat != null;
      case 1:
        return _title.text.trim().length >= 4 && _uploading == 0;
      case 2:
        return _addr.text.trim().length >= 5 && (_urgency != 'scheduled' || _when != null);
      default:
        return true;
    }
  }

  String? get _hint {
    if (_valid) return null;
    switch (_step) {
      case 0:
        return 'Elegí una categoría para seguir';
      case 1:
        return _uploading > 0 ? 'Esperá a que terminen de subir las fotos' : 'Poné un título corto (mínimo 4 letras)';
      case 2:
        return _urgency == 'scheduled' && _when == null ? 'Elegí día y hora' : 'Escribí la dirección completa';
    }
    return null;
  }

  Future<void> _pickPhotos(ImageSource src) async {
    try {
      final picker = ImagePicker();
      final files = src == ImageSource.camera
          ? [if (await picker.pickImage(source: src, maxWidth: 1600, imageQuality: 80) case final f?) f]
          : await picker.pickMultiImage(maxWidth: 1600, imageQuality: 80, limit: 5);
      if (files.isEmpty) return;
      for (final f in files.take(5 - _photos.length)) {
        setState(() => _uploading++);
        try {
          final url = await ref.read(apiProvider).upload(f.path);
          _photos.add(url);
          _save();
        } catch (e) {
          if (mounted) showSnack(context, 'No pudimos subir una foto: ${errorText(e)}', error: true);
        } finally {
          if (mounted) setState(() => _uploading--);
        }
      }
    } catch (_) {
      if (mounted) showSnack(context, 'No pudimos abrir la cámara o galería. Revisá los permisos.', error: true);
    }
  }

  Future<void> _useLocation() async {
    showSnack(context, 'Buscando tu ubicación…');
    final pos = await currentPosition();
    if (!mounted) return;
    if (pos == null) {
      showSnack(context, 'No pudimos obtener tu ubicación. Usamos el centro de Buenos Aires.', error: true);
      setState(() {
        _lat = AppConst.obelisco.latitude;
        _lng = AppConst.obelisco.longitude;
      });
    } else {
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      showSnack(context, 'Ubicación lista. Completá la dirección con calle y número.', ok: true);
    }
    _save();
  }

  Future<void> _pickWhen() async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, firstDate: now, lastDate: now.add(const Duration(days: 60)), initialDate: _when ?? now);
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_when ?? now.add(const Duration(hours: 2))));
    if (t == null) return;
    setState(() => _when = DateTime(d.year, d.month, d.day, t.hour, t.minute));
    _save();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final geo = ref.read(locationProvider).valueOrNull;
      final u = ref.read(authProvider).user;
      final lat = _lat ?? ((geo?.isDefault ?? true) && u?.lat != null ? u!.lat! : (geo?.ll.latitude ?? AppConst.obelisco.latitude));
      final lng = _lng ?? ((geo?.isDefault ?? true) && u?.lng != null ? u!.lng! : (geo?.ll.longitude ?? AppConst.obelisco.longitude));
      final b = int.tryParse(_budget.text.replaceAll(RegExp(r'[^0-9]'), ''));
      final r = await ref.read(apiProvider).createRequest({
        'categoryId': _cat,
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'photos': _photos,
        'lat': lat,
        'lng': lng,
        'address': _addr.text.trim(),
        if (b != null && b > 0) 'budgetMax': b,
        'urgency': _urgency,
        if (_urgency == 'scheduled' && _when != null) 'scheduledAt': _when!.toUtc().toIso8601String(),
      });
      await ref.read(prefsProvider).remove('requestDraft');
      ref.invalidate(myRequestsProvider);
      success();
      if (!mounted) return;
      showSnack(context, '¡Publicada! Los técnicos cercanos ya la están viendo.', ok: true);
      context.pushReplacement('/need/${r.id}');
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _discard() async {
    final ok = await confirmDialog(context, title: '¿Descartar el borrador?', message: 'Se borra lo que cargaste hasta ahora.', confirm: 'Descartar', danger: true);
    if (ok && mounted) {
      await ref.read(prefsProvider).remove('requestDraft');
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _step == 4;
    return PopScope(
      canPop: _step == 0,
      onPopInvoked: (didPop) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.pop()),
          title: Text('Paso ${_step + 1} de 5'),
          actions: [if (_cat != null || _title.text.isNotEmpty) TextButton(onPressed: _discard, child: const Text('Descartar'))],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: (_step + 1) / 5),
              duration: 350.ms,
              curve: Curves.easeOut,
              builder: (c, v, _) => LinearProgressIndicator(value: v, minHeight: 4, backgroundColor: context.cs.outlineVariant),
            ),
          ),
        ),
        body: Column(children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: 300.ms,
              transitionBuilder: (w, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(.05, 0), end: Offset.zero).animate(a), child: w)),
              child: SingleChildScrollView(
                key: ValueKey(_step),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_titles[_step], style: context.tt.headlineSmall),
                  const SizedBox(height: 18),
                  [_stepCategory, _stepDetails, _stepWhere, _stepBudget, _stepReview][_step](),
                ]),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(color: context.cs.surface, border: Border(top: BorderSide(color: context.cs.outlineVariant))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (_hint != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_hint!, style: TextStyle(fontSize: 12.5, color: context.cs.onSurfaceVariant))),
              Row(children: [
                if (_step > 0) ...[
                  SizedBox(width: 110, child: OutlinedButton(onPressed: () => setState(() => _step--), child: const Text('Atrás'))),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: AppButton(
                    label: last ? 'Publicar necesidad' : (_step == 3 && _budget.text.isEmpty ? 'Omitir' : 'Siguiente'),
                    icon: last ? Icons.rocket_launch_rounded : null,
                    loading: _busy,
                    onPressed: _valid
                        ? () {
                            FocusScope.of(context).unfocus();
                            if (last) {
                              _submit();
                            } else {
                              setState(() => _step++);
                              _save();
                            }
                          }
                        : null,
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  // ---- pasos
  Widget _stepCategory() {
    final cats = ref.watch(categoriesProvider);
    return cats.when(
      loading: () => const Skeleton(height: 300, radius: 20),
      error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(categoriesProvider)),
      data: (list) {
        final groups = <String, List<Category>>{};
        for (final c in list) {
          groups.putIfAbsent(c.group, () => []).add(c);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final e in groups.entries) ...[
            Padding(padding: const EdgeInsets.only(top: 6, bottom: 6), child: Text(e.key.toUpperCase(), style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w800, color: context.cs.onSurfaceVariant))),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: .78,
              children: [
                for (final c in e.value)
                  CategoryTile(
                      category: c,
                      selected: _cat == c.id,
                      onTap: () {
                        setState(() => _cat = c.id);
                        _save();
                      }),
              ],
            ),
          ],
        ]);
      },
    );
  }

  Widget _stepDetails() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: _title, textCapitalization: TextCapitalization.sentences, maxLength: 80, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Título corto', hintText: 'Ej: La heladera no enfría')),
      const SizedBox(height: 8),
      TextField(controller: _desc, minLines: 4, maxLines: 7, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Contanos más detalles', hintText: 'Desde cuándo pasa, marca y modelo, qué probaste…', alignLabelWithHint: true)),
      const SizedBox(height: 20),
      Text('Fotos (ayudan a recibir mejores ofertas)', style: context.tt.titleSmall),
      const SizedBox(height: 10),
      SizedBox(
        height: 92,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          if (_photos.length < 5) ...[
            _AddPhoto(Icons.photo_camera_rounded, 'Cámara', () => _pickPhotos(ImageSource.camera)),
            _AddPhoto(Icons.photo_library_rounded, 'Galería', () => _pickPhotos(ImageSource.gallery)),
          ],
          for (var i = 0; i < _photos.length; i++)
            Container(
              width: 92,
              margin: const EdgeInsets.only(right: 10),
              child: Stack(fit: StackFit.expand, children: [
                ClipRRect(borderRadius: BorderRadius.circular(rMd), child: Image.network(_photos[i], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: context.cs.surfaceVariant, child: const Icon(Icons.image_not_supported_outlined)))),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _photos.removeAt(i));
                      _save();
                    },
                    child: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close_rounded, size: 15, color: Colors.white)),
                  ),
                ),
              ]).animate().scale(duration: 250.ms, curve: Curves.easeOutBack),
            ),
          for (var i = 0; i < _uploading; i++) Container(width: 92, margin: const EdgeInsets.only(right: 10), child: const Skeleton(height: 92, radius: 16)),
        ]),
      ),
    ]);
  }

  Widget _stepWhere() {
    final cs = context.cs;
    Widget opt(String code, IconData icon, String title, String sub) {
      final sel = _urgency == code;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(rLg),
          onTap: () {
            tap();
            setState(() => _urgency = code);
            _save();
            if (code == 'scheduled' && _when == null) _pickWhen();
          },
          child: AnimatedContainer(
            duration: 200.ms,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: sel ? cs.primaryContainer : cs.surface,
              borderRadius: BorderRadius.circular(rLg),
              border: Border.all(color: sel ? cs.primary : cs.outlineVariant, width: sel ? 2 : 1),
            ),
            child: Row(children: [
              Icon(icon, color: sel ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), Text(sub, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))])),
              if (sel) Icon(Icons.check_circle_rounded, color: cs.primary),
            ]),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: _addr, textCapitalization: TextCapitalization.words, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Dirección', hintText: 'Calle, número, piso y depto', prefixIcon: Icon(Icons.location_on_outlined))),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(onPressed: _useLocation, icon: Icon(_lat != null ? Icons.check_circle_rounded : Icons.my_location_rounded, size: 18), label: Text(_lat != null ? 'Ubicación guardada (tocá para actualizar)' : 'Usar mi ubicación actual')),
      ),
      const SizedBox(height: 14),
      Text('¿Cuándo lo necesitás?', style: context.tt.titleSmall),
      const SizedBox(height: 10),
      opt('now', Icons.flash_on_rounded, 'Ahora', 'Es urgente, lo antes posible'),
      opt('today', Icons.today_rounded, 'Hoy', 'En el transcurso del día'),
      opt('scheduled', Icons.event_rounded, _when == null ? 'Programado' : 'Programado · ${fmtDateTime(_when)}', 'Elegí día y hora'),
      if (_urgency == 'scheduled') TextButton.icon(onPressed: _pickWhen, icon: const Icon(Icons.edit_calendar_rounded), label: const Text('Cambiar fecha y hora')),
    ]);
  }

  Widget _stepBudget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Si tenés un tope en mente, los técnicos lo van a ver y ajustar su oferta. Es opcional y no es un precio fijo.', style: TextStyle(color: context.cs.onSurfaceVariant, height: 1.45)),
      const SizedBox(height: 18),
      TextField(
        controller: _budget,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => setState(() {}),
        style: context.tt.headlineSmall,
        decoration: const InputDecoration(labelText: 'Presupuesto máximo', prefixText: '\$ ', hintText: '0'),
      ),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final v in [10000, 20000, 40000, 80000])
          ActionChip(
            label: Text(money(v)),
            onPressed: () {
              _budget.text = '$v';
              setState(() {});
            },
          ),
      ]),
    ]);
  }

  Widget _stepReview() {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final cat = cats.where((c) => c.id == _cat).firstOrNull;
    final b = int.tryParse(_budget.text);
    Widget row(IconData i, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(i, size: 20, color: context.cs.primary),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 12, color: context.cs.onSurfaceVariant)), Text(value, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3))])),
          ]),
        );
    return Column(children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            row(categoryIcon(cat?.icon ?? ''), 'Categoría', cat?.name ?? '—'),
            row(Icons.title_rounded, 'Título', _title.text.trim()),
            if (_desc.text.trim().isNotEmpty) row(Icons.notes_rounded, 'Detalle', _desc.text.trim()),
            row(Icons.location_on_rounded, 'Dirección', _addr.text.trim()),
            row(Icons.schedule_rounded, 'Cuándo', _urgency == 'now' ? 'Ahora' : (_urgency == 'today' ? 'Hoy' : fmtDateTime(_when))),
            row(Icons.payments_rounded, 'Presupuesto', b == null ? 'Sin tope' : 'Hasta ${money(b)}'),
            if (_photos.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(height: 64, child: ListView(scrollDirection: Axis.horizontal, children: [for (final p in _photos) Padding(padding: const EdgeInsets.only(right: 8), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(p, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 64))))])),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.cs.primaryContainer, borderRadius: BorderRadius.circular(rMd)),
        child: Row(children: [
          Icon(Icons.bolt_rounded, color: context.cs.primary),
          const SizedBox(width: 10),
          const Expanded(child: Text('Al publicar, los técnicos cercanos reciben el aviso y te mandan ofertas en minutos.', style: TextStyle(height: 1.35))),
        ]),
      ),
    ]);
  }
}


class _AddPhoto extends StatelessWidget {
  const _AddPhoto(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          tap();
          onTap();
        },
        child: Container(
          width: 92,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(color: context.cs.primaryContainer.withOpacity(.6), borderRadius: BorderRadius.circular(rMd), border: Border.all(color: context.cs.primary.withOpacity(.4))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: context.cs.primary), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.cs.primary))]),
        ),
      );
}

// ============================================================ DETALLE DE NECESIDAD + COMPARADOR
class RequestDetailScreen extends ConsumerStatefulWidget {
  const RequestDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  String _sort = 'best';
  Set<String>? _known;
  bool _accepting = false;

  static const sorts = [('best', 'Mejor opción'), ('price', 'Precio'), ('distance', 'Cercanía'), ('eta', 'Tiempo'), ('rating', 'Reputación')];

  List<Offer> _sorted(List<Offer> src) {
    final l = ensureBadges(src.where((o) => o.status == 'pending' || o.status == 'accepted').toList());
    double dist(Offer o) => o.distanceKm ?? o.tech?.distanceKm ?? 999;
    switch (_sort) {
      case 'price':
        l.sort((a, b) => a.price.compareTo(b.price));
      case 'distance':
        l.sort((a, b) => dist(a).compareTo(dist(b)));
      case 'eta':
        l.sort((a, b) => a.etaMinutes.compareTo(b.etaMinutes));
      case 'rating':
        l.sort((a, b) {
          final c = (b.tech?.ratingAvg ?? 0).compareTo(a.tech?.ratingAvg ?? 0);
          return c != 0 ? c : (b.tech?.ratingCount ?? 0).compareTo(a.tech?.ratingCount ?? 0);
        });
      default:
        l.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
    }
    return l;
  }

  Future<void> _accept(Offer o) async {
    final ok = await confirmDialog(
      context,
      title: '¿Aceptar esta oferta?',
      message: '${o.tech?.name ?? 'El técnico'} te cobra ${money(o.price)}, llega ${fmtEta(o.etaMinutes)} y tarda aprox. ${fmtMinutes(o.durationMinutes)}.\n\nEl pago queda protegido hasta que confirmes el trabajo.',
      confirm: 'Aceptar y pagar',
    );
    if (!ok) return;
    setState(() => _accepting = true);
    try {
      final job = await ref.read(apiProvider).acceptOffer(o.id);
      success();
      ref.invalidate(jobsProvider);
      ref.invalidate(myRequestsProvider);
      if (mounted) context.pushReplacement('/job/${job.id}/pay');
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  Future<void> _cancel() async {
    final ok = await confirmDialog(context, title: '¿Cancelar la necesidad?', message: 'Los técnicos dejarán de ver tu pedido y se descartan las ofertas.', confirm: 'Cancelar pedido', cancel: 'Mantener', danger: true);
    if (!ok) return;
    try {
      await ref.read(apiProvider).cancelRequest(widget.id);
      ref.invalidate(myRequestsProvider);
      ref.invalidate(requestDetailProvider(widget.id));
      if (mounted) showSnack(context, 'Pedido cancelado', ok: true);
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = ref.watch(requestDetailProvider(widget.id));
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final jobs = ref.watch(jobsProvider('client')).valueOrNull ?? [];
    final cs = context.cs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu necesidad'),
        actions: [
          if (res.valueOrNull?.request.isOpen ?? false)
            PopupMenuButton<String>(
              onSelected: (v) => v == 'cancel' ? _cancel() : null,
              itemBuilder: (_) => const [PopupMenuItem(value: 'cancel', child: Text('Cancelar pedido'))],
            ),
        ],
      ),
      body: AsyncBody<RequestDetail>(
        value: res,
        onRetry: () async => ref.refresh(requestDetailProvider(widget.id).future),
        builder: (d) {
          final r = d.request;
          final offers = _sorted(d.offers);
          _known ??= offers.map((o) => o.id).toSet();
          final job = jobs.where((j) => j.requestId == r.id && j.status != 'cancelled').firstOrNull;
          final cat = cats.where((c) => c.id == r.categoryId).firstOrNull;
          final prices = offers.map((o) => o.price).toList();
          return Stack(children: [
            ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(categoryIcon(cat?.icon ?? ''), color: cs.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(cat?.name ?? 'Necesidad', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700))),
                      StatusPill(r.status),
                    ]),
                    const SizedBox(height: 14),
                    Text(r.title, style: context.tt.titleLarge),
                    if (r.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(r.description, style: TextStyle(color: cs.onSurfaceVariant, height: 1.45))),
                    const SizedBox(height: 12),
                    Wrap(spacing: 14, runSpacing: 6, children: [
                      _mini(Icons.location_on_outlined, r.address),
                      _mini(Icons.bolt_rounded, r.urgency == 'scheduled' ? fmtDateTime(r.scheduledAt) : urgencyLabel(r.urgency)),
                      if (r.budgetMax != null) _mini(Icons.payments_outlined, 'Hasta ${money(r.budgetMax!)}'),
                    ]),
                    if (r.photos.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      SizedBox(height: 70, child: ListView(scrollDirection: Axis.horizontal, children: [for (final p in r.photos) Padding(padding: const EdgeInsets.only(right: 8), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(p, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 70))))])),
                    ],
                  ]),
                ),
              ),
              if (job != null) ...[
                const SizedBox(height: 14),
                GradientCard(
                  onTap: () => context.push(job.status == 'pending_payment' ? '/job/${job.id}/pay' : '/job/${job.id}'),
                  child: Row(children: [
                    const Icon(Icons.handyman_rounded, color: Colors.white, size: 30),
                    const SizedBox(width: 14),
                    Expanded(child: Text(job.status == 'pending_payment' ? 'Elegiste una oferta. Falta pagar.' : 'Ya tenés técnico asignado. Ver trabajo', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                  ]),
                ),
              ],
              if (r.isOpen || offers.isNotEmpty) ...[
                SectionHeader(offers.isEmpty ? 'Ofertas' : '${offers.length} ${offers.length == 1 ? 'oferta' : 'ofertas'} para comparar', padding: const EdgeInsets.fromLTRB(0, 26, 0, 6)),
                if (offers.isNotEmpty) ...[
                  Text('Desde ${money(prices.reduce(math.min))} hasta ${money(prices.reduce(math.max))}. Llegan en vivo, no hace falta actualizar.', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13.5)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    child: ListView(scrollDirection: Axis.horizontal, children: [
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
                  const SizedBox(height: 10),
                  for (var i = 0; i < offers.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: OfferCard(
                        key: ValueKey(offers[i].id),
                        offer: offers[i],
                        isNew: !(_known!.contains(offers[i].id)),
                        canAccept: r.isOpen,
                        onAccept: () => _accept(offers[i]),
                        onProfile: () => context.push('/t/${offers[i].techId}'),
                      ).animate(delay: (50 * math.min(i, 6)).ms, key: ValueKey('${offers[i].id}$_sort')).fadeIn().slideY(begin: .08),
                    ),
                ] else
                  _waiting(),
              ],
            ]),
            if (_accepting) Positioned.fill(child: Container(color: Colors.black38, child: const Center(child: CircularProgressIndicator()))),
          ]);
        },
        skeleton: const SkeletonList(),
      ),
    );
  }

  Widget _mini(IconData i, String t) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(i, size: 16, color: context.cs.onSurfaceVariant), const SizedBox(width: 4), Flexible(child: Text(t, style: TextStyle(fontSize: 13, color: context.cs.onSurfaceVariant, fontWeight: FontWeight.w600)))]);

  Widget _waiting() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(children: [
          Stack(alignment: Alignment.center, children: [
            Container(width: 120, height: 120, decoration: BoxDecoration(color: context.cs.primary.withOpacity(.08), shape: BoxShape.circle))
                .animate(onPlay: (c) => c.repeat())
                .scale(begin: const Offset(.6, .6), end: const Offset(1.2, 1.2), duration: 1600.ms)
                .fadeOut(duration: 1600.ms),
            Container(width: 76, height: 76, decoration: BoxDecoration(color: context.cs.primaryContainer, shape: BoxShape.circle), child: Icon(Icons.radar_rounded, size: 38, color: context.cs.primary)),
          ]),
          const SizedBox(height: 18),
          Text('Esperando ofertas…', style: context.tt.titleLarge),
          const SizedBox(height: 6),
          Text('Avisamos a los técnicos cercanos. Las ofertas aparecen acá apenas llegan.', textAlign: TextAlign.center, style: TextStyle(color: context.cs.onSurfaceVariant, height: 1.4)),
        ]),
      );
}

class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer, required this.onAccept, required this.onProfile, this.isNew = false, this.canAccept = true});
  final Offer offer;
  final VoidCallback onAccept, onProfile;
  final bool isNew, canAccept;
  @override
  Widget build(BuildContext context) {
    final o = offer;
    final t = o.tech;
    final cs = context.cs;
    final best = o.badges.contains('best');
    final dist = o.distanceKm ?? t?.distanceKm;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(rXl),
        border: Border.all(color: best ? cs.primary : cs.outlineVariant, width: best ? 2 : 1),
        boxShadow: best ? [BoxShadow(color: cs.primary.withOpacity(.18), blurRadius: 22, offset: const Offset(0, 8))] : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (o.badges.isNotEmpty || isNew)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              if (isNew) Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: FixiColors.lime, borderRadius: BorderRadius.circular(99)), child: const Text('¡Nueva!', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: FixiColors.ink))).animate(onPlay: (c) => c.repeat(reverse: true)).scale(end: const Offset(1.08, 1.08), duration: 700.ms),
              ...o.badges.map((b) => BadgeChip(b)),
            ]),
          ),
        InkWell(
          onTap: onProfile,
          borderRadius: BorderRadius.circular(12),
          child: Row(children: [
            FixiAvatar(url: t?.avatarUrl, name: t?.name ?? '?', size: 52, heroTag: 'tech-${o.techId}'),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Flexible(child: Text(t?.name ?? 'Técnico', overflow: TextOverflow.ellipsis, style: context.tt.titleMedium)), if (t?.verified ?? false) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified_rounded, size: 17, color: FixiColors.primary))]),
                const SizedBox(height: 5),
                Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  if (t != null) RatingChip(t.ratingAvg, t.ratingCount),
                  if (t != null) LevelBadge(t.level, compact: true),
                  if (t != null) Text('${t.points} pts', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ]),
              ]),
            ),
            Text(money(o.price), style: context.tt.headlineSmall?.copyWith(color: cs.primary, fontSize: 24)),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: InfoTile(icon: Icons.schedule_rounded, label: 'Llega', value: fmtMinutes(o.etaMinutes), color: FixiColors.warning)),
          const SizedBox(width: 8),
          Expanded(child: InfoTile(icon: Icons.timer_outlined, label: 'Dura', value: fmtMinutes(o.durationMinutes), color: FixiColors.success)),
          const SizedBox(width: 8),
          Expanded(child: InfoTile(icon: Icons.near_me_rounded, label: 'Distancia', value: fmtDistance(dist), color: const Color(0xFF8A4DFF))),
        ]),
        if (o.score != null) ...[
          const SizedBox(height: 14),
          Row(children: [
            Text('Puntaje Fixi', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: (o.score! / 100).clamp(0, 1)),
                  duration: 700.ms,
                  curve: Curves.easeOutCubic,
                  builder: (c, v, _) => LinearProgressIndicator(value: v, minHeight: 8, backgroundColor: cs.surfaceVariant, color: best ? cs.primary : cs.primary.withOpacity(.65)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('${fmtScore(o.score)}/100', style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
        ],
        if (o.message.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: cs.surfaceVariant.withOpacity(.6), borderRadius: BorderRadius.circular(rMd)),
            child: Text('“${o.message}”', style: TextStyle(fontStyle: FontStyle.italic, height: 1.4, color: cs.onSurface.withOpacity(.85))),
          ),
        ],
        if (canAccept) ...[
          const SizedBox(height: 14),
          Row(children: [
            SizedBox(width: 120, child: OutlinedButton(onPressed: onProfile, style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)), child: const Text('Ver perfil'))),
            const SizedBox(width: 10),
            Expanded(child: AppButton(label: 'Aceptar oferta', icon: Icons.check_rounded, onPressed: onAccept)),
          ]),
        ],
      ]),
    );
  }
}
