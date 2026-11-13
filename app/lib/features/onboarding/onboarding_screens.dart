import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

/// Marca de Fixi: cuadrado azul con rayo/llave.
class FixiMark extends StatelessWidget {
  const FixiMark({super.key, this.size = 88, this.onDark = true});
  final double size;
  final bool onDark;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onDark ? Colors.white : FixiColors.primary,
        borderRadius: BorderRadius.circular(size * .3),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.2), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      child: Stack(alignment: Alignment.center, children: [
        Text('F', style: TextStyle(fontSize: size * .62, fontWeight: FontWeight.w900, color: onDark ? FixiColors.primary : Colors.white, height: 1)),
        Positioned(
          right: size * .16,
          top: size * .14,
          child: Container(
            width: size * .26,
            height: size * .26,
            decoration: const BoxDecoration(color: FixiColors.lime, shape: BoxShape.circle),
            child: Icon(Icons.bolt_rounded, size: size * .19, color: FixiColors.ink),
          ),
        ),
      ]),
    );
  }
}

const _brandGradient = LinearGradient(colors: [Color(0xFF2F5BFF), Color(0xFF4B2FE0)], begin: Alignment.topLeft, end: Alignment.bottomRight);

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _brandGradient),
        width: double.infinity,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const FixiMark(size: 104).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
          const SizedBox(height: 24),
          Text('Fixi', style: context.tt.displaySmall?.copyWith(color: Colors.white, fontSize: 44)).animate(delay: 250.ms).fadeIn().slideY(begin: .3),
          const SizedBox(height: 8),
          Text('Técnicos de confianza, en tu puerta', style: TextStyle(color: Colors.white.withOpacity(.85), fontSize: 16, fontWeight: FontWeight.w500))
              .animate(delay: 450.ms)
              .fadeIn(),
          const SizedBox(height: 48),
          const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5, color: FixiColors.lime)).animate(delay: 700.ms).fadeIn(),
        ]),
      ),
    );
  }
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  static const _pages = [
    (Icons.build_circle_rounded, 'Contanos qué se rompió', 'Publicá tu necesidad con fotos en un minuto. Heladera, compu, caños o lo que sea: hay un técnico para eso.'),
    (Icons.compare_arrows_rounded, 'Compará y elegí tranquilo', 'Los técnicos te mandan ofertas con precio, tiempo de llegada y reputación. Vos elegís la mejor opción.'),
    (Icons.verified_user_rounded, 'Pagás seguro, sin vueltas', 'El pago se libera recién cuando confirmás que el trabajo está bien hecho. Y el seguimiento es en vivo.'),
  ];

  void _finish() {
    ref.read(settingsProvider.notifier).setOnboarded();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _brandGradient),
        child: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _finish, child: Text('Saltar', style: TextStyle(color: Colors.white.withOpacity(.9)))),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _pages.length,
                onPageChanged: (i) {
                  tap();
                  setState(() => _page = i);
                },
                itemBuilder: (_, i) {
                  final (icon, title, text) = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(.14), shape: BoxShape.circle),
                        child: Center(
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(icon, size: 72, color: FixiColors.primary),
                          ),
                        ),
                      ).animate(key: ValueKey(i)).scale(duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
                      const SizedBox(height: 40),
                      Text(title, textAlign: TextAlign.center, style: context.tt.headlineMedium?.copyWith(color: Colors.white, fontSize: 28)),
                      const SizedBox(height: 14),
                      Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(.88), fontSize: 16.5, height: 1.45)),
                    ]),
                  );
                },
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < _pages.length; i++)
                AnimatedContainer(
                  duration: 250.ms,
                  margin: const EdgeInsets.all(4),
                  width: i == _page ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(color: i == _page ? FixiColors.lime : Colors.white.withOpacity(.4), borderRadius: BorderRadius.circular(8)),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: FilledButton(
                onPressed: () {
                  bump();
                  if (last) {
                    _finish();
                  } else {
                    _pc.nextPage(duration: 350.ms, curve: Curves.easeOutCubic);
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: FixiColors.lime, foregroundColor: FixiColors.ink),
                child: Text(last ? 'Empezar' : 'Siguiente'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
