import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_client.dart';
import '../../core/models/models.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/format.dart';
import '../../core/widgets/common.dart';
import '../shared/shell.dart';

// ============================================================ PERFIL (pestaña)
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final u = auth.user;
    final tech = auth.tech;
    final cs = context.cs;
    final techMode = ref.watch(settingsProvider.select((s) => s.techMode)) && (u?.isTechnician ?? false);
    if (u == null) return const SizedBox.shrink();

    Widget tile(IconData icon, String title, VoidCallback onTap, {String? sub, Color? color}) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: (color ?? cs.primary).withOpacity(.12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color ?? cs.primary, size: 22)),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          subtitle: sub == null ? null : Text(sub),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            tap();
            onTap();
          },
        );

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => ref.read(authProvider.notifier).refresh(),
        child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
          Row(children: [Expanded(child: Text('Mi perfil', style: context.tt.headlineSmall)), const BellButton()]),
          const SizedBox(height: 12),
          Row(children: [
            FixiAvatar(url: u.avatarUrl, name: u.name, size: 72, heroTag: 'me-avatar'),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u.name, style: context.tt.titleLarge),
              Text(u.email, style: TextStyle(color: cs.onSurfaceVariant)),
              if (tech != null) Padding(padding: const EdgeInsets.only(top: 6), child: LevelBadge(tech.level, compact: true)),
            ])),
            IconButton.outlined(onPressed: () => context.push('/profile/edit'), icon: const Icon(Icons.edit_rounded)),
          ]).animate().fadeIn().slideY(begin: .1),
          const SizedBox(height: 20),
          if (u.isTechnician) ...[
            Text('Modo de uso', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            const ModeSwitch(large: true),
          ] else
            GradientCard(
              onTap: () => context.push('/tech-setup'),
              child: Row(children: [
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Ofrecé tus servicios', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text('Sumá ingresos como técnico. Recibís oportunidades cerca tuyo y cobrás dentro de la app.', style: TextStyle(color: Colors.white70, height: 1.35)),
                ])),
                Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: FixiColors.lime, shape: BoxShape.circle), child: const Icon(Icons.arrow_forward_rounded, color: FixiColors.ink)),
              ]),
            ),
          const SizedBox(height: 20),
          Card(
            child: Column(children: [
              if (u.isTechnician) ...[
                tile(Icons.badge_rounded, 'Perfil técnico', () => context.push('/tech-setup'), sub: 'Bio, categorías y radio de trabajo'),
                const Divider(indent: 70),
                if (techMode) ...[
                  tile(Icons.storefront_rounded, 'Mis servicios', () => context.push('/my-listings')),
                  const Divider(indent: 70),
                  tile(Icons.local_offer_rounded, 'Mis ofertas', () => context.push('/my-offers')),
                  const Divider(indent: 70),
                ],
              ],
              tile(Icons.person_rounded, 'Mis datos y dirección', () => context.push('/profile/edit')),
              const Divider(indent: 70),
              tile(Icons.settings_rounded, 'Ajustes', () => context.push('/settings'), sub: 'Tema y servidor'),
              const Divider(indent: 70),
              tile(Icons.help_outline_rounded, 'Ayuda', () => context.push('/help')),
            ]),
          ),
          const SizedBox(height: 16),
          Card(
            child: tile(Icons.logout_rounded, 'Cerrar sesión', () async {
              final ok = await confirmDialog(context, title: '¿Cerrar sesión?', message: 'Vas a tener que volver a ingresar para usar Fixi.', confirm: 'Cerrar sesión', danger: true);
              if (ok) ref.read(authProvider.notifier).logout();
            }, color: FixiColors.error),
          ),
        ]),
      ),
    );
  }
}

// ============================================================ EDITAR PERFIL
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final AppUser _u = ref.read(authProvider).user!;
  late final _name = TextEditingController(text: _u.name);
  late final _phone = TextEditingController(text: _u.phone ?? '');
  late final _addr = TextEditingController(text: _u.address ?? '');
  late String? _avatar = _u.avatarUrl;
  late double? _lat = _u.lat, _lng = _u.lng;
  bool _busy = false, _uploading = false;

  Future<void> _pickAvatar() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
      if (f == null) return;
      setState(() => _uploading = true);
      final url = await ref.read(apiProvider).upload(f.path);
      setState(() => _avatar = url);
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _locate() async {
    showSnack(context, 'Buscando tu ubicación…');
    final p = await currentPosition();
    if (!mounted) return;
    if (p == null) {
      showSnack(context, 'No pudimos obtener tu ubicación. Revisá el permiso de ubicación.', error: true);
    } else {
      setState(() {
        _lat = p.latitude;
        _lng = p.longitude;
      });
      showSnack(context, 'Ubicación guardada. Completá la dirección con calle y número.', ok: true);
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2) {
      showSnack(context, 'Ingresá tu nombre', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).patchMe({
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        if (_avatar != null) 'avatarUrl': _avatar,
        'address': _addr.text.trim(),
        if (_lat != null) 'lat': _lat,
        if (_lng != null) 'lng': _lng,
      });
      await ref.read(authProvider.notifier).refresh();
      ref.invalidate(locationProvider);
      success();
      if (mounted) {
        showSnack(context, 'Datos guardados', ok: true);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Mis datos')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), children: [
        Center(
          child: Stack(children: [
            FixiAvatar(url: _avatar, name: _name.text, size: 104, heroTag: 'me-avatar'),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: _uploading ? null : _pickAvatar,
                child: CircleAvatar(radius: 18, backgroundColor: context.cs.primary, child: _uploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.photo_camera_rounded, size: 18, color: Colors.white)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        TextField(controller: _name, textCapitalization: TextCapitalization.words, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Nombre y apellido', prefixIcon: Icon(Icons.person_outline_rounded))),
        const SizedBox(height: 14),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Celular', prefixIcon: Icon(Icons.phone_outlined))),
        const SizedBox(height: 14),
        TextField(controller: _addr, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Dirección habitual', hintText: 'Calle, número, piso', prefixIcon: Icon(Icons.home_outlined))),
        const SizedBox(height: 6),
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: _locate, icon: Icon(_lat != null ? Icons.check_circle_rounded : Icons.my_location_rounded, size: 18), label: Text(_lat != null ? 'Ubicación guardada (actualizar)' : 'Usar mi ubicación actual'))),
        const SizedBox(height: 18),
        AppButton(label: 'Guardar cambios', loading: _busy, onPressed: _save),
      ]),
    );
  }
}

// ============================================================ AJUSTES
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final connected = ref.watch(realtimeProvider).connected;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), children: [
        Text('Apariencia', style: context.tt.titleMedium),
        const SizedBox(height: 12),
        SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded, size: 18), label: Text('Sistema')),
            ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 18), label: Text('Claro')),
            ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 18), label: Text('Oscuro')),
          ],
          selected: {s.theme},
          onSelectionChanged: (v) {
            tap();
            ref.read(settingsProvider.notifier).setTheme(v.first);
          },
        ),
        const SizedBox(height: 28),
        Text('Servidor', style: context.tt.titleMedium),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const Icon(Icons.dns_rounded),
            title: Text(s.baseUrl, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: ValueListenableBuilder<bool>(valueListenable: connected, builder: (c, v, _) => Text(v ? 'Tiempo real conectado' : 'Tiempo real sin conexión')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/server'),
          ),
        ),
        const SizedBox(height: 28),
        Text('Acerca de', style: context.tt.titleMedium),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: FixiColors.primary, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.bolt_rounded, color: FixiColors.lime)), const SizedBox(width: 14), const Expanded(child: Text('Fixi 1.0.0\nTécnicos a domicilio, con pago protegido.', style: TextStyle(height: 1.4)))]))),
      ]),
    );
  }
}

// ============================================================ AYUDA
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  static const faqs = [
    ('¿Cómo pido un técnico?', 'Tocá “Publicar necesidad”, elegí la categoría, contanos qué pasa y dónde. Los técnicos cercanos te mandan ofertas y vos elegís. También podés reservar directo un servicio publicado.'),
    ('¿Cómo funciona el pago?', 'Pagás dentro de la app y el dinero queda protegido. Se libera al técnico recién cuando confirmás que el trabajo está terminado.'),
    ('¿Qué es la “Mejor opción”?', 'Un puntaje de 0 a 100 que combina precio, reputación, cercanía y tiempo de llegada, para ayudarte a comparar rápido.'),
    ('¿Cuánto cobra Fixi?', 'Fixi cobra una comisión del 5% al técnico sobre cada trabajo. Vos pagás el precio de la oferta, sin cargos extra.'),
    ('Algo salió mal con el trabajo', 'Desde el seguimiento del trabajo tocá “Reportar un problema”. Retenemos el pago y el equipo de Fixi lo revisa.'),
    ('Soy técnico, ¿cómo empiezo?', 'En tu perfil tocá “Ofrecé tus servicios”, completá tus categorías y radio, y vinculá Mercado Pago para cobrar.'),
    ('No me conecto al servidor', 'Entrá a Ajustes > Servidor y probá la conexión. En el emulador usá http://10.0.2.2:4000; en un celular real, la IP de la PC en tu red.'),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), children: [
        for (final (q, a) in faqs)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 18),
                  childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  title: Text(q, style: const TextStyle(fontWeight: FontWeight.w700)),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(a, style: TextStyle(height: 1.45, color: context.cs.onSurfaceVariant))],
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

// ============================================================ NOTIFICACIONES
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _marked = false;
  late final ProviderContainer _container;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context);
  }

  @override
  void dispose() {
    final c = _container;
    Future.microtask(() => c.invalidate(notificationsProvider));
    super.dispose();
  }

  IconData _icon(String t) {
    if (t.contains('offer')) return Icons.local_offer_rounded;
    if (t.contains('message')) return Icons.chat_bubble_rounded;
    if (t.contains('job') || t.contains('payment')) return Icons.handyman_rounded;
    if (t.contains('request')) return Icons.radar_rounded;
    return Icons.notifications_rounded;
  }

  void _open(AppNotification n) {
    final d = n.data;
    final jobId = d['jobId'];
    final reqId = d['requestId'];
    if (jobId != null) {
      context.push('/job/$jobId');
    } else if (reqId != null) {
      final tech = ref.read(settingsProvider).techMode;
      context.push(tech ? '/opportunity/$reqId' : '/need/$reqId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = ref.watch(notificationsProvider);
    final cs = context.cs;
    res.whenData((_) {
      if (!_marked) {
        _marked = true;
        ref.read(apiProvider).readAll().catchError((_) {});
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: AsyncBody<List<AppNotification>>(
        value: res,
        onRetry: () async => ref.refresh(notificationsProvider.future),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyState(icon: Icons.notifications_none_rounded, title: 'Todo al día', message: 'Cuando haya novedades de tus pedidos, ofertas o trabajos, las ves acá.');
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (c, i) {
              final n = items[i];
              return Card(
                color: n.read ? null : cs.primaryContainer.withOpacity(.5),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(_icon(n.type), color: cs.primary, size: 22)),
                  title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w600 : FontWeight.w800)),
                  subtitle: Text('${n.body}\n${timeAgo(n.createdAt)}', style: const TextStyle(height: 1.35)),
                  isThreeLine: true,
                  onTap: () => _open(n),
                ),
              ).animate(delay: (30 * (i > 8 ? 8 : i)).ms).fadeIn();
            },
          );
        },
      ),
    );
  }
}
