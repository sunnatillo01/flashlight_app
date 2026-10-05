import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:torch_light/torch_light.dart';
import 'package:url_launcher/url_launcher.dart';

// ---- Design tokens (from the design sheet) ----
const kPrimary = Color(0xFF2563EB);
const kOn = Color(0xFFFBBF24);
const kBg = Color(0xFF0F172A);
const kMuted = Color(0xFF64748B);
const kLight = Color(0xFFF3F4F6);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const FlashlightApp());
}

class FlashlightApp extends StatelessWidget {
  const FlashlightApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flashlight',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: kPrimary,
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        home: const HomePage(),
      );
}

enum TorchState { off, switching, on }

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  TorchState _state = TorchState.off;
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_state == TorchState.switching) return;
    final turnOn = _state == TorchState.off;
    HapticFeedback.mediumImpact();
    setState(() => _state = TorchState.switching);
    _spin.forward(from: 0);
    try {
      turnOn ? await TorchLight.enableTorch() : await TorchLight.disableTorch();
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) setState(() => _state = turnOn ? TorchState.on : TorchState.off);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = turnOn ? TorchState.off : TorchState.on);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chiroqni yoqib bo‘lmadi. Fonar mavjudligini tekshiring.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final on = _state == TorchState.on;
    final busy = _state == TorchState.switching;
    final title = busy ? 'Yoqilmoqda...' : on ? 'Chiroq yoniq' : 'Chiroq o‘chiq';
    final sub = busy
        ? 'Iltimos, kuting'
        : on
            ? 'Chiroqni o‘chirish uchun\ntugmani bosing'
            : 'Chiroqni yoqish uchun tugmani bosing';

    return Scaffold(
      backgroundColor: kBg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              const SizedBox(height: 16),
              _Header(onSettings: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
              const Spacer(),
              GestureDetector(
                onTap: _toggle,
                child: _PowerButton(on: on, busy: busy, spin: _spin),
              ),
              const SizedBox(height: 36),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: on || busy && false ? kOn : Colors.white)),
              const SizedBox(height: 10),
              Text(sub,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFCBD5E1))),
              const Spacer(),
              _TipCard(on: on),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onSettings;
  const _Header({required this.onSettings});
  @override
  Widget build(BuildContext context) => Row(children: [
        const _AppIcon(size: 52),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Flashlight',
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
            Text('Qulay va oddiy chiroq',
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8))),
          ]),
        ),
        IconButton(
            onPressed: onSettings,
            icon: const Icon(Icons.settings, color: Color(0xFF94A3B8))),
      ]);
}

class _AppIcon extends StatelessWidget {
  final double size;
  const _AppIcon({required this.size});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: kPrimary,
          borderRadius: BorderRadius.circular(size * .28),
        ),
        child: Icon(Icons.flashlight_on_rounded, color: Colors.white, size: size * .55),
      );
}

class _PowerButton extends StatelessWidget {
  final bool on, busy;
  final Animation<double> spin;
  const _PowerButton({required this.on, required this.busy, required this.spin});

  @override
  Widget build(BuildContext context) {
    final glow = on || busy;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: glow ? kOn.withOpacity(.10) : const Color(0xFF16213A),
        border: Border.all(
            color: glow ? kOn.withOpacity(.35) : const Color(0xFF1E2B4A), width: 8),
        boxShadow: on
            ? [BoxShadow(color: kOn.withOpacity(.45), blurRadius: 70, spreadRadius: 6)]
            : [],
      ),
      child: Stack(alignment: Alignment.center, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: on
                ? const RadialGradient(
                    colors: [Color(0xFFFDE047), kOn, Color(0xFFD97706)])
                : busy
                    ? const RadialGradient(colors: [Color(0xFF3B3A2F), Color(0xFF14192B)])
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF64748B), Color(0xFF334155)]),
          ),
          child: Icon(Icons.flashlight_on_rounded,
              size: busy ? 44 : 86,
              color: on ? Colors.white : busy ? kOn : const Color(0xFFE2E8F0)),
        ),
        if (busy)
          SizedBox(
            width: 200,
            height: 200,
            child: RotationTransition(
              turns: spin,
              child: const CircularProgressIndicator(
                  value: .28, strokeWidth: 6, color: kOn, strokeCap: StrokeCap.round),
            ),
          ),
      ]),
    );
  }
}

class _TipCard extends StatelessWidget {
  final bool on;
  const _TipCard({required this.on});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: on ? kOn.withOpacity(.14) : const Color(0xFF16213A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: on ? kOn.withOpacity(.4) : const Color(0xFF22304F)),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? kOn.withOpacity(.2) : const Color(0xFF1E2B4A)),
            child: const Icon(Icons.lightbulb_outline, color: kOn, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Maslahat',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              Text('Zarur bo‘lganda chiroqdan foydalaning.',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFCBD5E1))),
            ]),
          ),
        ]),
      );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _open(String url) async =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, VoidCallback)>[
      (Icons.wb_sunny_outlined, 'Ilova haqida', () => showAboutDialog(
            context: context,
            applicationName: 'Flashlight',
            applicationVersion: 'v1.0.0',
            applicationIcon: const _AppIcon(size: 48),
          )),
      // TODO: replace with your store link / in_app_review package.
      (Icons.star_border, 'Baholash', () => _open('https://play.google.com/store')),
      (Icons.share_outlined, 'Ulashish',
          () => Share.share('Flashlight — qulay va oddiy chiroq ilovasi')),
      // TODO: replace with your privacy policy URL.
      (Icons.shield_outlined, 'Maxfiylik siyosati', () => _open('https://example.com/privacy')),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Sozlamalar',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w600, color: kBg)),
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const SizedBox(height: 8),
        const Center(child: _AppIcon(size: 84)),
        const SizedBox(height: 14),
        Center(
            child: Text('Flashlight',
                style: GoogleFonts.poppins(
                    fontSize: 24, fontWeight: FontWeight.w600, color: kBg))),
        Center(
            child: Text('v1.0.0',
                style: GoogleFonts.poppins(fontSize: 13, color: kMuted))),
        const SizedBox(height: 28),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(children: [
            for (var i = 0; i < items.length; i++) ...[
              ListTile(
                leading: Icon(items[i].$1, color: kBg),
                title: Text(items[i].$2, style: GoogleFonts.poppins(fontSize: 14, color: kBg)),
                trailing: const Icon(Icons.chevron_right, color: kMuted),
                onTap: items[i].$3,
              ),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          ]),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFFEFF3FA), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(Icons.favorite, color: kBg),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Siz uchun qulay ilova',
                  style: GoogleFonts.poppins(fontSize: 12, color: kBg)),
              Text('Go‘zallik kichik narsalarda',
                  style: GoogleFonts.poppins(fontSize: 11, color: kMuted)),
            ]),
          ]),
        ),
      ]),
    );
  }
}
