import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../viewmodels/song_builder_viewmodel.dart';
import 'song_builder_result_screen.dart';

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────

class SongBuilderLoadingScreen extends StatefulWidget {
  const SongBuilderLoadingScreen({super.key});

  @override
  State<SongBuilderLoadingScreen> createState() =>
      _SongBuilderLoadingScreenState();
}

class _SongBuilderLoadingScreenState extends State<SongBuilderLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final SongBuilderViewModel _vm;

  bool _dataReady = false;
  bool _animDone = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _vm = context.read<SongBuilderViewModel>();
    _vm.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (!mounted || _hasNavigated) return;
    if (_vm.state == SongBuilderState.loaded) {
      _dataReady = true;
      _tryNavigate();
    } else if (_vm.state == SongBuilderState.error) {
      setState(() {});
    }
  }

  void _onAnimationComplete() {
    _animDone = true;
    _tryNavigate();
  }

  void _tryNavigate() {
    if (!_dataReady || !_animDone || _hasNavigated || !mounted) return;
    _hasNavigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SongBuilderResultScreen()),
    );
  }

  void _onCancel() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _vm.removeListener(_onStateChange);
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SongBuilderViewModel>();
    final isError = vm.state == SongBuilderState.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isError
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _ErrorBody(vm: vm),
                ),
              )
            : _AnimatedBody(
                animCtrl: _animCtrl,
                onAnimationComplete: _onAnimationComplete,
                onCancel: _onCancel,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ANIMATED BODY
// ─────────────────────────────────────────────

class _AnimatedBody extends StatefulWidget {
  final AnimationController animCtrl;
  final VoidCallback onAnimationComplete;
  final VoidCallback onCancel;

  const _AnimatedBody({
    required this.animCtrl,
    required this.onAnimationComplete,
    required this.onCancel,
  });

  @override
  State<_AnimatedBody> createState() => _AnimatedBodyState();
}

class _AnimatedBodyState extends State<_AnimatedBody> {
  final Stopwatch _sw = Stopwatch();
  int _currentPhase = 0;
  bool _animCompleteFired = false;

  static const _minAnimDuration = 15000;

  static const _phases = [
    _Phase(0, 'Catching your idea…', 'Gathering your creative vision'),
    _Phase(3000, 'Breaking it down…', 'Analyzing the core elements'),
    _Phase(
      5000,
      'Extracting the elements…',
      'Melody, lyrics, structure & more',
    ),
    _Phase(9000, 'Composing the pieces…', 'Bringing it all together'),
    _Phase(13000, 'Your song is taking shape…', 'Almost ready'),
  ];

  @override
  void initState() {
    super.initState();
    _sw.start();
    widget.animCtrl.addListener(_tick);
  }

  void _tick() {
    final elapsed = _sw.elapsedMilliseconds;
    int phase = 0;
    for (int i = _phases.length - 1; i >= 0; i--) {
      if (elapsed >= _phases[i].ms) {
        phase = i;
        break;
      }
    }
    if (phase != _currentPhase) setState(() => _currentPhase = phase);
    if (!_animCompleteFired && elapsed >= _minAnimDuration) {
      _animCompleteFired = true;
      widget.onAnimationComplete();
    }
  }

  @override
  void dispose() {
    widget.animCtrl.removeListener(_tick);
    _sw.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phases[_currentPhase];

    return Column(
      children: [
        // ── Canvas ──
        Expanded(
          child: AnimatedBuilder(
            animation: widget.animCtrl,
            builder: (context, _) {
              return CustomPaint(
                painter: _CosmicBirthPainter(
                  elapsed: _sw.elapsedMilliseconds,
                  primary: AppColors.primary,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),

        // ── Status text ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Column(
              key: ValueKey(_currentPhase),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  _buildHighlightedText(phase.title),
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w300,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  phase.subtitle,
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

        // ── Cancel ──
        Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: GestureDetector(
            onTap: widget.onCancel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Stop building',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  TextSpan _buildHighlightedText(String text) {
    const keywords = {
      'Catching',
      'Breaking',
      'Extracting',
      'Composing',
      'shape',
    };
    final words = text.split(' ');
    return TextSpan(
      children: words.asMap().entries.map((entry) {
        final i = entry.key;
        final w = entry.value;
        final clean = w.replaceAll(RegExp(r'[^a-zA-Z]'), '');
        final isH = keywords.contains(clean);
        return TextSpan(
          text: '${i > 0 ? ' ' : ''}$w',
          style: isH
              ? TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)
              : null,
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────
//  PHASE DATA
// ─────────────────────────────────────────────

class _Phase {
  final int ms;
  final String title;
  final String subtitle;
  const _Phase(this.ms, this.title, this.subtitle);
}

// ─────────────────────────────────────────────
//  COSMIC BIRTH PAINTER
// ─────────────────────────────────────────────

class _CosmicBirthPainter extends CustomPainter {
  final int elapsed;
  final Color primary;
  static final Random _rng = Random(99);

  // Pre-computed element data (stable across frames)
  static List<_FloatingElement>? _elements;
  static List<_TrailParticle>? _trail;
  static List<_ImpactSpark>? _sparks;

  _CosmicBirthPainter({required this.elapsed, required this.primary});

  // Phase timings
  static const _descEnd = 3000;
  static const _impactFlash = 3200;
  static const _emergeStart = 4500;
  static const _assembleStart = 9000;
  static const _assembleEnd = 13000;

  // Ground line Y as fraction of height
  static const _groundY = 0.55;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final gy = size.height * _groundY; // ground Y
    final t = elapsed.toDouble();

    _initElements(cx, gy);

    _drawBackgroundParticles(canvas, size, t);
    _drawGroundLine(canvas, cx, gy, size.width, t);
    _drawOrb(canvas, cx, gy, t);
    _drawShockwave(canvas, cx, gy, t);
    _drawImpactSparks(canvas, cx, gy, t);
    _drawFloatingElements(canvas, cx, gy, t, size);
    _drawFinalOrb(canvas, cx, gy, t);
  }

  // ── Initialize stable element positions ──

  void _initElements(double cx, double gy) {
    if (_elements != null) return;

    final labels = [
      'Melody',
      'Lyrics',
      'Structure',
      'Vibe',
      'Hook',
      '♪',
      '♫',
      '♩',
    ];
    _elements = List.generate(labels.length, (i) {
      final angle = (i / labels.length) * pi * 2 + _rng.nextDouble() * 0.5;
      final dist = 80.0 + _rng.nextDouble() * 70;
      return _FloatingElement(
        label: labels[i],
        angle: angle,
        maxDist: dist,
        floatSpeed: 0.5 + _rng.nextDouble() * 1.0,
        floatPhase: _rng.nextDouble() * pi * 2,
        delay: i * 500, // stagger emergence
        isSymbol:
            labels[i].startsWith('♪') ||
            labels[i].startsWith('♫') ||
            labels[i].startsWith('♩'),
      );
    });

    _trail = List.generate(
      20,
      (_) => _TrailParticle(
        offsetX: (_rng.nextDouble() - 0.5) * 6,
        offsetY: _rng.nextDouble() * 15 + 5,
        size: _rng.nextDouble() * 2.5 + 0.8,
        opacity: _rng.nextDouble() * 0.4 + 0.2,
      ),
    );

    _sparks = List.generate(16, (i) {
      final angle = (i / 16) * pi * 2 + (_rng.nextDouble() - 0.5) * 0.3;
      return _ImpactSpark(
        angle: angle,
        speed: 60.0 + _rng.nextDouble() * 100,
        size: _rng.nextDouble() * 2.5 + 1.0,
        life: 600.0 + _rng.nextDouble() * 600,
      );
    });
  }

  // ── Background particles (always present) ──

  void _drawBackgroundParticles(Canvas canvas, Size size, double t) {
    final paint = Paint();
    final rng = Random(42);
    for (int i = 0; i < 20; i++) {
      final bx =
          (rng.nextDouble() * size.width + sin(t * 0.0005 + i) * 8) %
          size.width;
      final by =
          (rng.nextDouble() * size.height + t * 0.01 * (i % 3 + 1)) %
          size.height;
      final br = rng.nextDouble() * 1.5 + 0.4;
      final bo = rng.nextDouble() * 0.15 + 0.03;

      paint
        ..color = primary.withValues(alpha: bo * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(bx, by), br * 2.5, paint);

      paint
        ..color = primary.withValues(alpha: bo)
        ..maskFilter = null;
      canvas.drawCircle(Offset(bx, by), br, paint);
    }
  }

  // ── Ground line ──

  void _drawGroundLine(
    Canvas canvas,
    double cx,
    double gy,
    double width,
    double t,
  ) {
    // Only appears after impact
    if (elapsed < _descEnd) return;

    final age = (elapsed - _descEnd).toDouble();
    final fadeIn = (age / 1000).clamp(0.0, 1.0);

    // Crack/ripple width grows from impact point
    final crackWidth = (age / 800).clamp(0.0, 1.0) * width * 0.4;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = primary.withValues(alpha: fadeIn * 0.15);

    // Main line
    canvas.drawLine(
      Offset(cx - crackWidth, gy),
      Offset(cx + crackWidth, gy),
      paint,
    );

    // Ripple marks
    if (age > 300) {
      final rippleAlpha = (1.0 - (age - 300) / 3000).clamp(0.0, 1.0) * 0.1;
      paint.color = primary.withValues(alpha: rippleAlpha);
      for (int i = 1; i <= 3; i++) {
        final rw = crackWidth * (0.3 + i * 0.2);
        final ry = gy + i * 4.0;
        canvas.drawLine(
          Offset(cx - rw, ry),
          Offset(cx + rw, ry),
          paint..strokeWidth = 0.5,
        );
      }
    }
  }

  // ── Falling orb (Phase 1) ──

  void _drawOrb(Canvas canvas, double cx, double gy, double t) {
    if (elapsed > _impactFlash + 400) return; // gone after impact

    double orbY;
    double orbSize = 12;
    double orbOpacity = 1.0;

    if (elapsed < _descEnd) {
      // Falling with acceleration (ease-in quadratic)
      final progress = (elapsed / _descEnd.toDouble());
      final eased = progress * progress; // accelerate
      final startY = -20.0;
      orbY = startY + eased * (gy - startY);

      // Slight glow increase as it falls
      orbSize = 10 + eased * 4;
    } else {
      // Impact — shrink and flash
      final impAge = (elapsed - _descEnd).toDouble();
      final shrink = (1.0 - impAge / 400).clamp(0.0, 1.0);
      orbY = gy;
      orbSize = 14 * shrink;
      orbOpacity = shrink;
    }

    if (orbOpacity < 0.01) return;

    // Trail particles during descent
    if (elapsed < _descEnd && _trail != null) {
      final paint = Paint();
      for (final tp in _trail!) {
        final ty = orbY + tp.offsetY;
        final tx = cx + tp.offsetX + sin(t * 0.01 + tp.offsetX) * 2;
        final trailFade =
            (1.0 - (tp.offsetY / 25)).clamp(0.0, 1.0) * tp.opacity;

        paint
          ..color = primary.withValues(alpha: trailFade * 0.3)
          ..maskFilter = null;
        canvas.drawCircle(Offset(tx, ty), tp.size * 0.7, paint);
      }
    }

    // Outer glow
    final glowPaint = Paint()
      ..color = primary.withValues(alpha: orbOpacity * 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(cx, orbY), orbSize * 3, glowPaint);

    // Mid glow
    glowPaint
      ..color = primary.withValues(alpha: orbOpacity * 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(cx, orbY), orbSize * 1.8, glowPaint);

    // Core
    final corePaint = Paint()
      ..color = primary.withValues(alpha: orbOpacity * 0.9);
    canvas.drawCircle(Offset(cx, orbY), orbSize, corePaint);

    // Bright center
    final brightPaint = Paint()
      ..color = Colors.white.withValues(alpha: orbOpacity * 0.6);
    canvas.drawCircle(Offset(cx, orbY), orbSize * 0.4, brightPaint);
  }

  // ── Shockwave ring (on impact) ──

  void _drawShockwave(Canvas canvas, double cx, double gy, double t) {
    if (elapsed < _descEnd || elapsed > _descEnd + 1500) return;

    final age = (elapsed - _descEnd).toDouble();
    final progress = age / 1500;
    final radius = progress * 180;
    final alpha = (1.0 - progress) * 0.3;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * (1.0 - progress)
      ..color = primary.withValues(alpha: alpha);

    canvas.drawCircle(Offset(cx, gy), radius, paint);

    // Second ring (delayed)
    if (age > 200) {
      final p2 = (age - 200) / 1500;
      if (p2 < 1.0) {
        paint
          ..strokeWidth = 1.5 * (1.0 - p2)
          ..color = primary.withValues(alpha: (1.0 - p2) * 0.15);
        canvas.drawCircle(Offset(cx, gy), p2 * 150, paint);
      }
    }

    // Screen flash (very subtle)
    if (age < 300) {
      final flash = (1.0 - age / 300) * 0.06;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, 500, 1000),
        Paint()..color = primary.withValues(alpha: flash),
      );
    }
  }

  // ── Impact sparks ──

  void _drawImpactSparks(Canvas canvas, double cx, double gy, double t) {
    if (elapsed < _descEnd || _sparks == null) return;

    final age = (elapsed - _descEnd).toDouble();
    final paint = Paint();

    for (final spark in _sparks!) {
      if (age > spark.life) continue;

      final progress = age / spark.life;
      final dist = spark.speed * progress * (1.0 - progress * 0.5);
      final sx = cx + cos(spark.angle) * dist;
      final sy = gy + sin(spark.angle) * dist * 0.6 - progress * 20; // arc up
      final alpha = (1.0 - progress) * 0.7;
      final size = spark.size * (1.0 - progress * 0.5);

      paint.color = primary.withValues(alpha: alpha);
      canvas.drawCircle(Offset(sx, sy), size, paint);
    }
  }

  // ── Floating elements (words + symbols) ──

  void _drawFloatingElements(
    Canvas canvas,
    double cx,
    double gy,
    double t,
    Size size,
  ) {
    if (elapsed < _emergeStart || _elements == null) return;

    final emergeAge = (elapsed - _emergeStart).toDouble();

    for (final el in _elements!) {
      final elAge = emergeAge - el.delay;
      if (elAge < 0) continue;

      // Phase: emerge outward, then pull back to center
      double dx, dy, alpha;

      if (elapsed < _assembleStart) {
        // Emerging outward
        final outProgress = (elAge / 2000).clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(outProgress);
        final dist = el.maxDist * eased;

        // Float wobble
        final wobbleX = sin(t * 0.002 * el.floatSpeed + el.floatPhase) * 8;
        final wobbleY = cos(t * 0.0015 * el.floatSpeed + el.floatPhase) * 6;

        dx = cx + cos(el.angle) * dist + wobbleX;
        dy = gy + sin(el.angle) * dist * 0.7 - 30 + wobbleY; // bias upward
        alpha = eased * 0.85;
      } else {
        // Pulling back toward center
        final pullProgress =
            ((elapsed - _assembleStart) / (_assembleEnd - _assembleStart))
                .clamp(0.0, 1.0);
        final eased = Curves.easeInOutCubic.transform(pullProgress);

        final fullDist = el.maxDist;
        final wobbleX =
            sin(t * 0.002 * el.floatSpeed + el.floatPhase) * 8 * (1 - eased);
        final wobbleY =
            cos(t * 0.0015 * el.floatSpeed + el.floatPhase) * 6 * (1 - eased);

        final currentDist = fullDist * (1 - eased);
        dx = cx + cos(el.angle) * currentDist + wobbleX;
        dy = gy + sin(el.angle) * currentDist * 0.7 - 30 + wobbleY;
        alpha = 0.85 * (1 - eased * 0.7); // fade as they merge

        // Connection lines during assembly
        if (eased > 0.2 && eased < 0.9) {
          final lineAlpha = (eased - 0.2) * 0.15;
          final linePaint = Paint()
            ..color = primary.withValues(alpha: lineAlpha)
            ..strokeWidth = 0.5;
          canvas.drawLine(Offset(dx, dy), Offset(cx, gy - 30), linePaint);
        }
      }

      if (alpha < 0.01) continue;

      // Draw glow behind text
      final glowPaint = Paint()
        ..color = primary.withValues(alpha: alpha * 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(dx, dy), 20, glowPaint);

      // Draw the text/symbol
      final tp = TextPainter(
        text: TextSpan(
          text: el.label,
          style: TextStyle(
            color: primary.withValues(alpha: alpha),
            fontSize: el.isSymbol ? 20 : 12,
            fontWeight: el.isSymbol ? FontWeight.w400 : FontWeight.w500,
            letterSpacing: el.isSymbol ? 0 : 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(dx - tp.width / 2, dy - tp.height / 2));
    }
  }

  // ── Final merged orb (Phase 5) ──

  void _drawFinalOrb(Canvas canvas, double cx, double gy, double t) {
    if (elapsed < _assembleEnd) return;

    final age = (elapsed - _assembleEnd).toDouble();
    final fadeIn = (age / 1000).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(fadeIn);

    final orbY = gy - 30;
    final breathe = sin(t * 0.002) * 0.08;
    final baseSize = 18.0 * eased;
    final size = baseSize * (1 + breathe);

    // Outer glow
    final glowPaint = Paint()
      ..color = primary.withValues(alpha: eased * 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawCircle(Offset(cx, orbY), size * 4, glowPaint);

    // Mid ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = primary.withValues(alpha: eased * 0.2);
    canvas.drawCircle(Offset(cx, orbY), size * 2.5, ringPaint);

    // Inner glow
    glowPaint
      ..color = primary.withValues(alpha: eased * 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(cx, orbY), size * 1.5, glowPaint);

    // Core diamond shape
    final corePaint = Paint()
      ..color = primary.withValues(alpha: eased * 0.8)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(cx, orbY - size); // top
    path.lineTo(cx + size * 0.7, orbY); // right
    path.lineTo(cx, orbY + size); // bottom
    path.lineTo(cx - size * 0.7, orbY); // left
    path.close();
    canvas.drawPath(path, corePaint);

    // Bright center
    final brightPaint = Paint()
      ..color = Colors.white.withValues(alpha: eased * 0.4);
    canvas.drawCircle(Offset(cx, orbY), size * 0.25, brightPaint);

    // Orbiting particles
    if (eased > 0.5) {
      final orbitAlpha = (eased - 0.5) * 2;
      final orbitPaint = Paint();
      for (int i = 0; i < 5; i++) {
        final angle = t * 0.002 + (i / 5) * pi * 2;
        final orbitR = size * 2.8 + sin(t * 0.003 + i) * 4;
        final ox = cx + cos(angle) * orbitR;
        final oy = orbY + sin(angle) * orbitR * 0.5; // elliptical

        orbitPaint.color = primary.withValues(alpha: orbitAlpha * 0.5);
        canvas.drawCircle(Offset(ox, oy), 2, orbitPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicBirthPainter oldDelegate) =>
      oldDelegate.elapsed != elapsed;
}

// ─────────────────────────────────────────────
//  DATA CLASSES
// ─────────────────────────────────────────────

class _FloatingElement {
  final String label;
  final double angle;
  final double maxDist;
  final double floatSpeed;
  final double floatPhase;
  final int delay;
  final bool isSymbol;

  const _FloatingElement({
    required this.label,
    required this.angle,
    required this.maxDist,
    required this.floatSpeed,
    required this.floatPhase,
    required this.delay,
    required this.isSymbol,
  });
}

class _TrailParticle {
  final double offsetX, offsetY, size, opacity;
  const _TrailParticle({
    required this.offsetX,
    required this.offsetY,
    required this.size,
    required this.opacity,
  });
}

class _ImpactSpark {
  final double angle, speed, size, life;
  const _ImpactSpark({
    required this.angle,
    required this.speed,
    required this.size,
    required this.life,
  });
}

// ─────────────────────────────────────────────
//  ERROR STATE
// ─────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final SongBuilderViewModel vm;

  const _ErrorBody({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.danger.withValues(alpha: 0.1),
          ),
          child: const Icon(
            Icons.error_outline,
            color: AppColors.danger,
            size: 32,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AppStrings.songBuilder.errorTitle,
          style: AppTextStyles.heading3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          vm.errorMessage ?? AppStrings.songBuilder.errorGeneric,
          style: AppTextStyles.bodySecondary.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedAppButton(
                text: AppStrings.songBuilder.cancelButton,
                height: 48,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GreenButton(
                text: AppStrings.songBuilder.retryButton,
                height: 48,
                onPressed: () => vm.regenerate(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
