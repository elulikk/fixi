import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/config/constants.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../onboarding/onboarding_screens.dart';

String? _validEmail(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Ingresá tu email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return 'Ese email no parece válido';
  return null;
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false, _hide = true;
  String? _error;

  Future<void> _do(Future<void> Function() fn) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await fn();
      success();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = errorText(e));
      HapticFeedbackError();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ignore: non_constant_identifier_names
  void HapticFeedbackError() => bump();

  void _submit() {
    if (!_form.currentState!.validate()) return;
    _do(() => ref.read(authProvider.notifier).login(_email.text, _pass.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _form,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(onPressed: () => context.push('/server'), tooltip: 'Servidor', icon: const Icon(Icons.dns_rounded)),
              ),
              const FixiMark(size: 64, onDark: false).animate().fadeIn().slideY(begin: .2),
              const SizedBox(height: 24),
              Text('Bienvenido a Fixi', style: context.tt.headlineMedium).animate(delay: 100.ms).fadeIn(),
              const SizedBox(height: 6),
              Text('Entrá para pedir o dar servicio técnico.', style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 16)),
              const SizedBox(height: 28),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
                validator: _validEmail,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pass,
                obscureText: _hide,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(onPressed: () => setState(() => _hide = !_hide), icon: Icon(_hide ? Icons.visibility_rounded : Icons.visibility_off_rounded)),
                ),
                validator: (v) => (v ?? '').isEmpty ? 'Ingresá tu contraseña' : null,
              ),
              if (_error != null) _ErrorBanner(_error!),
              const SizedBox(height: 22),
              AppButton(label: 'Entrar', onPressed: _submit, loading: _busy),
              const SizedBox(height: 22),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('o probá la demo', style: TextStyle(color: context.cs.onSurfaceVariant))),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _do(() => ref.read(authProvider.notifier).login(AppConst.demoClientEmail, AppConst.demoPassword)),
                    icon: const Icon(Icons.person_rounded),
                    label: const Text('Demo cliente'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _do(() => ref.read(authProvider.notifier).login(AppConst.demoTechEmail, AppConst.demoPassword, asTech: true)),
                    icon: const Icon(Icons.handyman_rounded),
                    label: const Text('Demo técnico'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  ),
                ),
              ]),
              const SizedBox(height: 26),
              Center(
                child: TextButton(onPressed: () => context.push('/register'), child: const Text('¿Primera vez? Creá tu cuenta')),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: FixiColors.error.withOpacity(.12), borderRadius: BorderRadius.circular(rMd)),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, color: FixiColors.error),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: FixiColors.error, fontWeight: FontWeight.w600))),
        ]),
      ).animate().shake(hz: 3, duration: 400.ms).fadeIn();
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false, _hide = true;
  String? _error;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).register(_name.text, _email.text, _pass.text, _phone.text);
      success();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _form,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Creá tu cuenta', style: context.tt.headlineMedium),
              const SizedBox(height: 6),
              Text('Es gratis y lleva un minuto.', style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 16)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre y apellido', prefixIcon: Icon(Icons.person_outline_rounded)),
                validator: (v) => (v ?? '').trim().length < 2 ? 'Contanos tu nombre' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
                validator: _validEmail,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Celular (opcional)', prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pass,
                obscureText: _hide,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  helperText: 'Mínimo 6 caracteres',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(onPressed: () => setState(() => _hide = !_hide), icon: Icon(_hide ? Icons.visibility_rounded : Icons.visibility_off_rounded)),
                ),
                validator: (v) => (v ?? '').length < 6 ? 'Usá al menos 6 caracteres' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                obscureText: _hide,
                decoration: const InputDecoration(labelText: 'Repetí la contraseña', prefixIcon: Icon(Icons.lock_reset_rounded)),
                validator: (v) => v != _pass.text ? 'Las contraseñas no coinciden' : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              if (_error != null) _ErrorBanner(_error!),
              const SizedBox(height: 24),
              AppButton(label: 'Crear cuenta', onPressed: _submit, loading: _busy),
              const SizedBox(height: 12),
              Center(child: Text('Al registrarte aceptás los términos y la política de privacidad.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: context.cs.onSurfaceVariant))),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    );
  }
}

class ServerScreen extends ConsumerStatefulWidget {
  const ServerScreen({super.key});
  @override
  ConsumerState<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends ConsumerState<ServerScreen> {
  late final _url = TextEditingController(text: ref.read(settingsProvider).baseUrl);
  bool _testing = false;
  bool? _ok;

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _ok = null;
    });
    var u = _url.text.trim();
    if (!u.startsWith('http')) u = 'http://$u';
    final ok = await ApiClient.health(u);
    if (!mounted) return;
    setState(() {
      _testing = false;
      _ok = ok;
    });
    ok ? success() : bump();
  }

  void _save() {
    ref.read(settingsProvider.notifier).setBaseUrl(_url.text);
    ref.read(realtimeProvider).restart();
    showSnack(context, 'Servidor guardado', ok: true);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Servidor')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Text('Dirección del servidor de Fixi. En el emulador de Android usá 10.0.2.2; en un celular real, la IP de la PC en tu red (por ejemplo http://192.168.0.15:4000).',
            style: TextStyle(color: context.cs.onSurfaceVariant, height: 1.45)),
        const SizedBox(height: 20),
        TextField(
          controller: _url,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(labelText: 'URL base', prefixIcon: Icon(Icons.dns_rounded), hintText: 'http://10.0.2.2:4000'),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 8, children: [
          ActionChip(label: const Text('Emulador'), onPressed: () => _url.text = AppConst.defaultBaseUrl),
          ActionChip(label: const Text('Esta PC (localhost)'), onPressed: () => _url.text = 'http://localhost:4000'),
        ]),
        const SizedBox(height: 20),
        AppButton(label: 'Probar conexión', outlined: true, icon: Icons.wifi_tethering_rounded, loading: _testing, onPressed: _test),
        if (_ok != null)
          Container(
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: (_ok! ? FixiColors.success : FixiColors.error).withOpacity(.12), borderRadius: BorderRadius.circular(rMd)),
            child: Row(children: [
              Icon(_ok! ? Icons.check_circle_rounded : Icons.cancel_rounded, color: _ok! ? FixiColors.success : FixiColors.error),
              const SizedBox(width: 10),
              Expanded(child: Text(_ok! ? '¡Conectado! El servidor responde.' : 'No pudimos conectar. Revisá la URL y que el servidor esté encendido.', style: TextStyle(fontWeight: FontWeight.w600, color: _ok! ? FixiColors.success : FixiColors.error))),
            ]),
          ).animate().fadeIn().slideY(begin: .2),
        const SizedBox(height: 24),
        AppButton(label: 'Guardar', onPressed: _save),
      ]),
    );
  }
}
