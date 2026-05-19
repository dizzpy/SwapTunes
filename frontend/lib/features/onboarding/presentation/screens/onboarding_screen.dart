import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../auth/presentation/widgets/auth_bottom_sheet.dart';

// ─────────────────────────────────────────────
// Inline colour / style constants
// (replace with your real AppColors / AppTextStyles imports)
// ─────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF191A1A);
  static const primary = Color(0xFF10B981);
  static const primaryDim = Color(0xFF0D9268);
  // static const greenDark = Color(0xFF0F2E24);
  static const textWhite = Color(0xFFF3F5F7);
  static const textMuted = Color(0xFFA7A9A9);
  static const outline = Color(0xFF434747);
  static const card = Color(0xFF232525);
}

// ─────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _ctrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _showAuth() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AuthBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 20),
                child: GestureDetector(
                  onTap: _showAuth,
                  child: AnimatedOpacity(
                    opacity: _page < 2 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _C.outline.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: _C.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Pages
            Expanded(
              child: PageView(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [_Page1(), _Page2(), _Page3()],
              ),
            ),

            // ── Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 28 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active ? _C.primary : _C.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),

            // ── CTA
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _page == 2 ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: _page != 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: _showAuth,
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF0A7A5A)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _C.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Get Started',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// PAGE 1 — Sound Waveform
// "Share your sound" — animated equalizer bars
// ═══════════════════════════════════════════════════════
class _Page1 extends StatefulWidget {
  const _Page1();
  @override
  State<_Page1> createState() => _Page1State();
}

class _Page1State extends State<_Page1> with TickerProviderStateMixin {
  late final List<AnimationController> _bars;
  final _rng = math.Random(42);

  @override
  void initState() {
    super.initState();
    _bars = List.generate(18, (i) {
      final c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500 + _rng.nextInt(600)),
      )..repeat(reverse: true);
      Future.delayed(Duration(milliseconds: _rng.nextInt(400)), c.forward);
      return c;
    });
  }

  @override
  void dispose() {
    for (final b in _bars) {
      b.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      hero: SizedBox(
        width: 280,
        height: 200,
        child: AnimatedBuilder(
          animation: Listenable.merge(_bars),
          builder: (context, child) {
            return CustomPaint(
              painter: _WaveformPainter(_bars.map((b) => b.value).toList()),
            );
          },
        ),
      ),
      pill: 'LISTENING',
      title: 'Share your sound',
      subtitle:
          'Post songs, playlists, and music moments with people who get your taste.',
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> values;
  _WaveformPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final count = values.length;
    final barW = (size.width / count) * 0.55;
    final gap = (size.width - barW * count) / (count + 1);
    final midY = size.height / 2;
    final maxH = size.height * 0.42;
    final minH = size.height * 0.06;

    for (int i = 0; i < count; i++) {
      final x = gap + i * (barW + gap);
      final h = minH + (maxH - minH) * values[i];
      final alpha = 0.4 + 0.6 * values[i];

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _C.primary.withValues(alpha: alpha),
            _C.primary.withValues(alpha: alpha * 0.3),
          ],
        ).createShader(Rect.fromLTWH(x, midY - h, barW, h * 2))
        ..style = PaintingStyle.fill;

      final rr = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barW / 2, midY),
          width: barW,
          height: h * 2,
        ),
        Radius.circular(barW / 2),
      );
      canvas.drawRRect(rr, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => true;
}

// ═══════════════════════════════════════════════════════
// PAGE 2 — Vinyl Record
// "Find fresh music" — rotating vinyl with painter grooves
// ═══════════════════════════════════════════════════════
class _Page2 extends StatefulWidget {
  const _Page2();
  @override
  State<_Page2> createState() => _Page2State();
}

class _Page2State extends State<_Page2> with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      hero: AnimatedBuilder(
        animation: _spin,
        builder: (context, child) => Transform.rotate(
          angle: _spin.value * 2 * math.pi,
          child: CustomPaint(
            size: const Size(220, 220),
            painter: _VinylPainter(),
          ),
        ),
      ),
      pill: 'DISCOVER',
      title: 'Find fresh music',
      subtitle:
          'Explore creators, genres, and playlists shaped around what you listen to.',
    );
  }
}

class _VinylPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Outer disc
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF1C1F1F));

    // Grooves
    final gPaint = Paint()
      ..color = const Color(0xFF2A2E2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (double gr = r * 0.35; gr < r * 0.95; gr += r * 0.052) {
      canvas.drawCircle(c, gr, gPaint);
    }

    // Shimmer arc
    final shimmer = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.5],
      ).createShader(Rect.fromCircle(center: c, radius: r))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(c, r, shimmer);

    // Inner label
    canvas.drawCircle(
      c,
      r * 0.28,
      Paint()
        ..shader = RadialGradient(
          colors: [_C.primary, _C.primaryDim],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.28)),
    );

    // Label glow
    canvas.drawCircle(
      c,
      r * 0.28,
      Paint()
        ..color = _C.primary.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Centre hole
    canvas.drawCircle(c, r * 0.04, Paint()..color = _C.bg);

    // Outer rim
    canvas.drawCircle(
      c,
      r - 0.5,
      Paint()
        ..color = _C.outline.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_VinylPainter old) => false;
}

// ═══════════════════════════════════════════════════════
// PAGE 3 — Collab Nodes
// "Create together" — pulsing connection graph
// ═══════════════════════════════════════════════════════
class _Page3 extends StatefulWidget {
  const _Page3();
  @override
  State<_Page3> createState() => _Page3State();
}

class _Page3State extends State<_Page3> with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _orbit;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      hero: SizedBox(
        width: 240,
        height: 220,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulse, _orbit]),
          builder: (context, child) =>
              CustomPaint(painter: _CollabPainter(_pulse.value, _orbit.value)),
        ),
      ),
      pill: 'COLLAB',
      title: 'Create together',
      subtitle:
          'Match with other music lovers and build collaborations from one place.',
    );
  }
}

class _CollabPainter extends CustomPainter {
  final double pulse;
  final double orbit;
  _CollabPainter(this.pulse, this.orbit);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Satellite nodes positions
    const nodeCount = 5;
    final orbitR = size.width * 0.36;
    final satellites = List.generate(nodeCount, (i) {
      final angle = (2 * math.pi / nodeCount) * i + orbit * 2 * math.pi;
      return Offset(
        cx + orbitR * math.cos(angle),
        cy + orbitR * math.sin(angle),
      );
    });

    // Connection lines from centre to each satellite
    final linePaint = Paint()
      ..color = _C.primary.withValues(alpha: 0.18 + 0.12 * pulse)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (final s in satellites) {
      canvas.drawLine(Offset(cx, cy), s, linePaint);
    }

    // Cross connections (every other node)
    final crossPaint = Paint()
      ..color = _C.primary.withValues(alpha: 0.08 + 0.06 * pulse)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < nodeCount; i++) {
      canvas.drawLine(
        satellites[i],
        satellites[(i + 2) % nodeCount],
        crossPaint,
      );
    }

    // Satellite nodes
    for (int i = 0; i < nodeCount; i++) {
      final s = satellites[i];
      final nodeR = 10.0 + (i == 0 ? 3.0 * pulse : 0);

      // Glow
      canvas.drawCircle(
        s,
        nodeR + 6,
        Paint()
          ..color = _C.primary.withValues(alpha: 0.12 + 0.08 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Fill
      canvas.drawCircle(
        s,
        nodeR,
        Paint()..color = i == 0 ? _C.primary : _C.card,
      );

      // Border
      canvas.drawCircle(
        s,
        nodeR,
        Paint()
          ..color = _C.primary.withValues(alpha: i == 0 ? 0.0 : 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Music note icon proxy (small dot)
      if (i != 0) {
        canvas.drawCircle(
          s,
          3,
          Paint()..color = _C.primary.withValues(alpha: 0.8),
        );
      }
    }

    // Centre node — large pulsing
    final centreR = 28.0 + 4 * pulse;

    // Outer pulse ring
    canvas.drawCircle(
      Offset(cx, cy),
      centreR + 14 + 6 * pulse,
      Paint()
        ..color = _C.primary.withValues(alpha: 0.07 + 0.05 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Centre glow
    canvas.drawCircle(
      Offset(cx, cy),
      centreR + 6,
      Paint()
        ..color = _C.primary.withValues(alpha: 0.2 + 0.1 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Centre fill
    canvas.drawCircle(
      Offset(cx, cy),
      centreR,
      Paint()
        ..shader = RadialGradient(colors: [_C.primary, _C.primaryDim])
            .createShader(
              Rect.fromCircle(center: Offset(cx, cy), radius: centreR),
            ),
    );

    // Match % text
    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '92',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15 + 1.5 * pulse,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const TextSpan(
            text: '%',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_CollabPainter old) => true;
}

// ═══════════════════════════════════════════════════════
// Shared page shell
// ═══════════════════════════════════════════════════════
class _PageShell extends StatelessWidget {
  final Widget hero;
  final String pill;
  final String title;
  final String subtitle;

  const _PageShell({
    required this.hero,
    required this.pill,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero area with glow backdrop
          Stack(
            alignment: Alignment.center,
            children: [
              // Glow blob
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _C.primary.withValues(alpha: 0.08),
                      _C.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              hero,
            ],
          ),
          const SizedBox(height: 40),

          // Pill label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _C.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _C.primary.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Text(
              pill,
              style: const TextStyle(
                color: _C.primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _C.textWhite,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _C.textMuted,
                fontSize: 14.5,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
