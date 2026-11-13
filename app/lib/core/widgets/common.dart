import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

extension Ctx on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

void tap() => HapticFeedback.selectionClick();
void bump() => HapticFeedback.mediumImpact();
void success() => HapticFeedback.heavyImpact();

final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

void showSnack(BuildContext? context, String msg, {bool error = false, bool ok = false}) {
  final m = context != null ? ScaffoldMessenger.maybeOf(context) ?? messengerKey.currentState : messengerKey.currentState;
  m?.hideCurrentSnackBar();
  m?.showSnackBar(SnackBar(
    content: Row(children: [
      Icon(error ? Icons.error_outline : (ok ? Icons.check_circle_outline : Icons.info_outline),
          color: error ? FixiColors.error : (ok ? FixiColors.success : null), size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(msg)),
    ]),
    duration: const Duration(seconds: 3),
  ));
}

// ---------------------------------------------------------------- iconos
const _icons = <String, IconData>{
  'computer': Icons.computer_rounded,
  'laptop': Icons.laptop_mac_rounded,
  'laptop_mac': Icons.laptop_mac_rounded,
  'desktop_windows': Icons.desktop_windows_rounded,
  'smartphone': Icons.smartphone_rounded,
  'phone_android': Icons.smartphone_rounded,
  'phone_iphone': Icons.smartphone_rounded,
  'tablet': Icons.tablet_mac_rounded,
  'devices': Icons.devices_rounded,
  'wifi': Icons.wifi_rounded,
  'router': Icons.router_rounded,
  'sports_esports': Icons.sports_esports_rounded,
  'videogame_asset': Icons.sports_esports_rounded,
  'print': Icons.print_rounded,
  'kitchen': Icons.kitchen_rounded,
  'local_laundry_service': Icons.local_laundry_service_rounded,
  'ac_unit': Icons.ac_unit_rounded,
  'tv': Icons.tv_rounded,
  'speaker': Icons.speaker_rounded,
  'microwave': Icons.microwave_rounded,
  'oven': Icons.microwave_rounded,
  'cooking': Icons.soup_kitchen_rounded,
  'bolt': Icons.bolt_rounded,
  'electrical_services': Icons.electrical_services_rounded,
  'plumbing': Icons.plumbing_rounded,
  'water_drop': Icons.water_drop_rounded,
  'local_fire_department': Icons.local_fire_department_rounded,
  'gas_meter': Icons.local_fire_department_rounded,
  'key': Icons.key_rounded,
  'lock': Icons.lock_rounded,
  'format_paint': Icons.format_paint_rounded,
  'imagesearch_roller': Icons.format_paint_rounded,
  'construction': Icons.construction_rounded,
  'handyman': Icons.handyman_rounded,
  'home_repair_service': Icons.home_repair_service_rounded,
  'build': Icons.build_rounded,
  'more_horiz': Icons.more_horiz_rounded,
  'category': Icons.category_rounded,
};

IconData categoryIcon(String name) => _icons[name] ?? Icons.build_circle_rounded;

// ---------------------------------------------------------------- avatar
class FixiAvatar extends StatelessWidget {
  const FixiAvatar({super.key, this.url, required this.name, this.size = 44, this.heroTag});
  final String? url;
  final String name;
  final double size;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((e) => e[0].toUpperCase()).join();
    final hue = (name.codeUnits.fold<int>(0, (a, b) => a + b) * 37) % 360;
    final bg = HSLColor.fromAHSL(1, hue.toDouble(), .55, context.isDark ? .35 : .88).toColor();
    final fg = HSLColor.fromAHSL(1, hue.toDouble(), .6, context.isDark ? .85 : .30).toColor();
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: bg,
      child: Text(initials, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: size * .38)),
    );
    final child = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: (url == null || url!.isEmpty)
            ? fallback
            : CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover, placeholder: (_, __) => fallback, errorWidget: (_, __, ___) => fallback),
      ),
    );
    return heroTag == null ? child : Hero(tag: heroTag!, child: child);
  }
}

// ---------------------------------------------------------------- insignias
class LevelBadge extends StatelessWidget {
  const LevelBadge(this.level, {super.key, this.compact = false});
  final String level;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final c = FixiColors.level(level);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 10, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(color: c.withOpacity(.14), borderRadius: BorderRadius.circular(99), border: Border.all(color: c.withOpacity(.4))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.workspace_premium_rounded, size: compact ? 13 : 16, color: c),
        const SizedBox(width: 3),
        Text(Levels.label(level), style: TextStyle(fontSize: compact ? 11 : 12.5, fontWeight: FontWeight.w700, color: c)),
      ]),
    );
  }
}

class RatingChip extends StatelessWidget {
  const RatingChip(this.avg, this.count, {super.key, this.size = 14});
  final double avg;
  final int count;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.star_rounded, size: size + 2, color: FixiColors.warning),
      const SizedBox(width: 2),
      Text(count == 0 ? 'Nuevo' : avg.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.w700, fontSize: size)),
      if (count > 0) Text(' ($count)', style: TextStyle(fontSize: size - 1, color: context.cs.onSurfaceVariant)),
    ]);
  }
}

class StarsRow extends StatelessWidget {
  const StarsRow(this.value, {super.key, this.size = 18});
  final int value;
  final double size;
  @override
  Widget build(BuildContext context) => Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(i < value ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: FixiColors.warning)));
}

class BadgeChip extends StatelessWidget {
  const BadgeChip(this.code, {super.key});
  final String code;

  static (String, IconData, Color) spec(String c) {
    switch (c) {
      case 'best':
        return ('Mejor opción', Icons.auto_awesome_rounded, FixiColors.primary);
      case 'cheapest':
        return ('Más barato', Icons.savings_rounded, FixiColors.success);
      case 'closest':
        return ('Más cerca', Icons.near_me_rounded, const Color(0xFF8A4DFF));
      case 'fastest':
        return ('Más rápido', Icons.bolt_rounded, const Color(0xFFE08A00));
      case 'top_rated':
        return ('Mejor puntuado', Icons.star_rounded, const Color(0xFFE5484D));
      default:
        return (c, Icons.label_rounded, FixiColors.primary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = spec(code);
    final solid = code == 'best';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: solid ? color : color.withOpacity(context.isDark ? .22 : .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: solid ? Colors.white : color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: solid ? Colors.white : color)),
      ]),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final String status;

  static (String, Color) spec(String s) {
    switch (s) {
      case 'pending_payment':
        return ('Falta pagar', FixiColors.warning);
      case 'paid':
        return ('Pago listo', FixiColors.primary);
      case 'on_the_way':
        return ('En camino', const Color(0xFF8A4DFF));
      case 'in_progress':
        return ('En curso', const Color(0xFFE08A00));
      case 'done':
        return ('Terminado', FixiColors.success);
      case 'completed':
        return ('Completado', FixiColors.success);
      case 'cancelled':
        return ('Cancelado', const Color(0xFF8A93A8));
      case 'disputed':
        return ('En disputa', FixiColors.error);
      case 'open':
        return ('Abierta', FixiColors.primary);
      case 'assigned':
        return ('Asignada', FixiColors.success);
      case 'closed':
        return ('Cerrada', const Color(0xFF8A93A8));
      case 'pending':
        return ('Pendiente', FixiColors.warning);
      case 'accepted':
        return ('Aceptada', FixiColors.success);
      case 'rejected':
        return ('Rechazada', FixiColors.error);
      case 'withdrawn':
        return ('Retirada', const Color(0xFF8A93A8));
      default:
        return (s, const Color(0xFF8A93A8));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (label, color) = spec(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ---------------------------------------------------------------- carga / vacío / error
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = 10});
  final double? width;
  final double height, radius;
  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Shimmer.fromColors(
      baseColor: dark ? const Color(0xFF1D2438) : const Color(0xFFE6E9F3),
      highlightColor: dark ? const Color(0xFF2A3350) : const Color(0xFFF6F7FB),
      child: Container(width: width, height: height, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius))),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 120});
  final double height;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Skeleton(width: 48, height: 48, radius: 24),
            const SizedBox(width: 14),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Skeleton(width: 160, height: 16),
              const SizedBox(height: 10),
              const Skeleton(height: 12),
              const SizedBox(height: 8),
              Skeleton(width: height > 100 ? 220 : 120, height: 12),
            ])),
          ]),
        ),
      );
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.padding = const EdgeInsets.all(20)});
  final int count;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const SkeletonCard(),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.actionLabel, this.onAction});
  final IconData icon;
  final String title, message;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(color: context.cs.primaryContainer, shape: BoxShape.circle),
            child: Icon(icon, size: 52, color: context.cs.primary),
          ).animate().scale(duration: 450.ms, curve: Curves.easeOutBack).fadeIn(),
          const SizedBox(height: 22),
          Text(title, style: context.tt.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message, style: context.tt.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant, height: 1.4), textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 22),
            FilledButton(onPressed: onAction, style: FilledButton.styleFrom(minimumSize: const Size(180, 50)), child: Text(actionLabel!)),
          ],
        ]).animate().fadeIn(duration: 300.ms),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    final net = error is ApiException && (error as ApiException).isNetwork;
    return EmptyState(
      icon: net ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
      title: net ? 'Sin conexión con el servidor' : 'Ups, algo falló',
      message: errorText(error),
      actionLabel: 'Reintentar',
      onAction: onRetry,
    );
  }
}

/// Renderiza un AsyncValue con esqueleto, error con reintento y pull-to-refresh.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.onRetry, required this.builder, this.skeleton});
  final AsyncValue<T> value;
  final Future<void> Function() onRetry;
  final Widget Function(T data) builder;
  final Widget? skeleton;
  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnReload: true,
      loading: () => skeleton ?? const SkeletonList(),
      error: (e, _) => RefreshIndicator(onRefresh: onRetry, child: LayoutBuilder(builder: (c, cons) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: cons.maxHeight, child: ErrorState(error: e, onRetry: onRetry))))),
      data: (d) => RefreshIndicator(onRefresh: onRetry, child: builder(d)),
    );
  }
}

// ---------------------------------------------------------------- bloques
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 12)});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(children: [
          Expanded(child: Text(title, style: context.tt.titleMedium?.copyWith(fontSize: 18))),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ]),
      );
}

class AppButton extends StatelessWidget {
  const AppButton({super.key, required this.label, required this.onPressed, this.loading = false, this.icon, this.outlined = false, this.color});
  final String label;
  final VoidCallback? onPressed;
  final bool loading, outlined;
  final IconData? icon;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: outlined ? null : context.cs.onPrimary))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ]);
    void go() {
      bump();
      onPressed!();
    }

    final cb = (loading || onPressed == null) ? null : go;
    return outlined
        ? OutlinedButton(onPressed: cb, child: child)
        : FilledButton(onPressed: cb, style: color == null ? null : FilledButton.styleFrom(backgroundColor: color), child: child);
  }
}

class InfoTile extends StatelessWidget {
  const InfoTile({super.key, required this.icon, required this.label, required this.value, this.color});
  final IconData icon;
  final String label, value;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(color: context.cs.surfaceVariant.withOpacity(context.isDark ? .6 : .55), borderRadius: BorderRadius.circular(rMd)),
      child: Column(children: [
        Icon(icon, size: 20, color: color ?? context.cs.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14), textAlign: TextAlign.center),
        Text(label, style: TextStyle(fontSize: 11.5, color: context.cs.onSurfaceVariant), textAlign: TextAlign.center),
      ]),
    );
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category, required this.onTap, this.selected = false});
  final Category category;
  final VoidCallback onTap;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return InkWell(
      borderRadius: BorderRadius.circular(rMd),
      onTap: () {
        tap();
        onTap();
      },
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(rMd),
          border: Border.all(color: selected ? cs.primary : Colors.transparent, width: 1.5),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(18)),
            child: Icon(categoryIcon(category.icon), color: cs.primary, size: 27),
          ),
          const SizedBox(height: 7),
          Text(category.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.15)),
        ]),
      ),
    );
  }
}

Future<bool> confirmDialog(BuildContext context,
    {required String title, required String message, String confirm = 'Confirmar', String cancel = 'Volver', bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44), backgroundColor: danger ? FixiColors.error : null),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return r ?? false;
}

class GradientCard extends StatelessWidget {
  const GradientCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(20), this.colors});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final List<Color>? colors;
  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(rXl),
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(rXl),
          gradient: LinearGradient(colors: colors ?? const [Color(0xFF2F5BFF), Color(0xFF5B3CFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: FixiColors.primary.withOpacity(.28), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: InkWell(onTap: onTap == null ? null : () { tap(); onTap!(); }, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

/// Estrellas interactivas para calificar.
class StarPicker extends StatelessWidget {
  const StarPicker({super.key, required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final on = i < value;
          return IconButton(
            iconSize: 42,
            onPressed: () {
              tap();
              onChanged(i + 1);
            },
            icon: Icon(on ? Icons.star_rounded : Icons.star_outline_rounded, color: on ? FixiColors.warning : context.cs.outline)
                .animate(key: ValueKey('$i$on'))
                .scale(begin: const Offset(.8, .8), duration: 200.ms, curve: Curves.easeOutBack),
          );
        }),
      );
}
