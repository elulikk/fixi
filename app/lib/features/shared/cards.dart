import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config/constants.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/format.dart';
import '../../core/widgets/common.dart';

class FixiMap extends StatelessWidget {
  const FixiMap({super.key, required this.center, this.zoom = 13.5, this.markers = const [], this.controller, this.interactive = true, this.onTap, this.fit});
  final LatLng center;
  final double zoom;
  final List<Marker> markers;
  final MapController? controller;
  final bool interactive;
  final VoidCallback? onTap;

  /// Si trae 2+ puntos, el mapa arranca encuadrándolos a todos.
  final List<LatLng>? fit;
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        initialCameraFit: (fit != null && fit!.length >= 2) ? CameraFit.coordinates(coordinates: fit!, padding: const EdgeInsets.all(48), maxZoom: 16) : null,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: InteractionOptions(flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none),
        onTap: onTap == null ? null : (_, __) => onTap!(),
      ),
      children: [
        TileLayer(urlTemplate: AppConst.osmTiles, userAgentPackageName: AppConst.userAgentPackage),
        MarkerLayer(markers: markers),
        const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap')], alignment: AttributionAlignment.bottomLeft),
      ],
    );
  }
}

Marker pinMarker(LatLng p, IconData icon, Color color, {double size = 44}) => Marker(
      point: p,
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Icon(icon, color: Colors.white, size: size * .5),
      ),
    );

Marker labelMarker(LatLng p, String label, Color color, {bool selected = false, VoidCallback? onTap}) => Marker(
      point: p,
      width: 92,
      height: 40,
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? FixiColors.ink : color,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
          ),
        ),
      ),
    );

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap, this.compact = false});
  final Listing listing;
  final VoidCallback onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final l = listing;
    final t = l.tech;
    final cs = context.cs;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          tap();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (l.badges.isNotEmpty) ...[
              Wrap(spacing: 6, runSpacing: 6, children: l.badges.map((b) => BadgeChip(b)).toList()),
              const SizedBox(height: 12),
            ],
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FixiAvatar(url: t?.avatarUrl, name: t?.name ?? '?', size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium),
                  const SizedBox(height: 4),
                  Row(children: [
                    Flexible(child: Text(t?.name ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600))),
                    if (t?.verified ?? false) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified_rounded, size: 16, color: FixiColors.primary)),
                  ]),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    if (t != null) RatingChip(t.ratingAvg, t.ratingCount),
                    if (t != null) LevelBadge(t.level, compact: true),
                  ]),
                ]),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                if (l.pricePrefix.isNotEmpty) Text(l.pricePrefix.trim(), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                Text(money(l.price), style: context.tt.titleLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w800)),
                if (l.priceSuffix.isNotEmpty) Text(l.priceSuffix.trim(), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ]),
            ]),
            if (!compact) ...[
              const SizedBox(height: 14),
              Wrap(spacing: 16, runSpacing: 6, children: [
                _Meta(Icons.near_me_rounded, fmtDistance(l.distanceKm ?? t?.distanceKm)),
                _Meta(Icons.schedule_rounded, l.etaMinutes != null ? 'Llega ${fmtMinutes(l.etaMinutes)}' : '—'),
                _Meta(Icons.timer_outlined, fmtMinutes(l.durationMinutes)),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: context.cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: context.cs.onSurfaceVariant, fontWeight: FontWeight.w600))),
        ]);
}

String urgencyLabel(String u) => u == 'now' ? 'Ahora' : (u == 'today' ? 'Hoy' : 'Programado');

class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.request, required this.onTap, this.categories = const [], this.showDistance = false, this.trailing});
  final NeedRequest request;
  final VoidCallback onTap;
  final List<Category> categories;
  final bool showDistance;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final r = request;
    final cat = categories.where((c) => c.id == r.categoryId).firstOrNull;
    final cs = context.cs;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          tap();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(16)),
              child: Icon(categoryIcon(cat?.icon ?? ''), color: cs.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium),
                const SizedBox(height: 4),
                Text(cat?.name ?? r.categoryName ?? '', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(spacing: 12, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  StatusPill(r.status),
                  _Meta(Icons.bolt_rounded, urgencyLabel(r.urgency)),
                  if (showDistance) _Meta(Icons.near_me_rounded, fmtDistance(r.distanceKm)),
                  if (r.budgetMax != null) _Meta(Icons.payments_outlined, 'hasta ${money(r.budgetMax!)}'),
                  _Meta(Icons.local_offer_outlined, '${r.offersCount} ${r.offersCount == 1 ? 'oferta' : 'ofertas'}'),
                ]),
              ]),
            ),
            if (trailing != null) trailing!,
          ]),
        ),
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job, required this.clientView, required this.onTap});
  final Job job;
  final bool clientView;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final name = clientView ? (job.tech?.name ?? 'Técnico') : (job.client?.name ?? 'Cliente');
    final avatar = clientView ? job.tech?.avatarUrl : job.client?.avatarUrl;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          tap();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            FixiAvatar(url: avatar, name: name, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(job.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium),
                const SizedBox(height: 3),
                Text(name, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 8),
                Row(children: [StatusPill(job.status), const SizedBox(width: 8), Text(timeAgo(job.createdAt), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))]),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(money(clientView ? job.price : job.techNet), style: context.tt.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w800)),
              if (!clientView) Text('neto', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              const SizedBox(height: 6),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ]),
          ]),
        ),
      ),
    );
  }
}
