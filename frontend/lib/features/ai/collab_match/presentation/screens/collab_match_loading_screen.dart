import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../viewmodels/collab_match_viewmodel.dart';
import 'collab_match_screen.dart';

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────

class CollabMatchLoadingScreen extends StatefulWidget {
  final String collabId;
  final String collabTitle;

  const CollabMatchLoadingScreen({
    super.key,
    required this.collabId,
    required this.collabTitle,
  });

  @override
  State<CollabMatchLoadingScreen> createState() =>
      _CollabMatchLoadingScreenState();
}

class _CollabMatchLoadingScreenState extends State<CollabMatchLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final CollabMatchViewModel _vm;
  late final AnimationController _animCtrl;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _vm = context.read<CollabMatchViewModel>();
    _vm.addListener(_onVmChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _vm.fetchMatches(widget.collabId);
    });
  }

  void _onVmChange() {
    if (!mounted || _hasNavigated) return;
    if (_vm.state == CollabMatchState.loaded) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CollabMatchScreen(
              collabId: widget.collabId,
              collabTitle: widget.collabTitle,
            ),
          ),
        );
      });
    }
  }

  void _onCancel() {
    _vm.cancelMatch();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChange);
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollabMatchViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: vm.state == CollabMatchState.error
            ? _ErrorBody(
                message: vm.errorMessage ?? AppStrings.collab.matchError,
                onRetry: () {
                  _hasNavigated = false;
                  _vm.fetchMatches(widget.collabId);
                },
                onCancel: _onCancel,
              )
            : _AnimatedBody(
                animCtrl: _animCtrl,
                collabTitle: widget.collabTitle,
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
  final String collabTitle;
  final VoidCallback onCancel;

  const _AnimatedBody({
    required this.animCtrl,
    required this.collabTitle,
    required this.onCancel,
  });

  @override
  State<_AnimatedBody> createState() => _AnimatedBodyState();
}

class _AnimatedBodyState extends State<_AnimatedBody> {
  final Stopwatch _sw = Stopwatch();
  int _currentPhase = 0;

  static const _phases = [
    _Phase(
      0,
      'Sending out your signal…',
      'Scanning creators across all genres',
    ),
    _Phase(3000, 'Reading your frequency…', 'Analyzing genre, role & vibe'),
    _Phase(7000, 'Finding your wavelength…', 'Comparing with creator profiles'),
    _Phase(11000, 'Tuning into matches…', 'Evaluating compatibility scores'),
    _Phase(15000, 'Finalizing your matches…', 'Almost there'),
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
    if (phase != _currentPhase) {
      setState(() => _currentPhase = phase);
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
        const SizedBox(height: 8),

        // ── Collab title chip ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.music_note_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.collabTitle,
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Waveform area ──
        Expanded(
          child: AnimatedBuilder(
            animation: widget.animCtrl,
            builder: (context, _) {
              return CustomPaint(
                painter: _FrequencyPainter(
                  elapsed: _sw.elapsedMilliseconds,
                  primary: AppColors.primary,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),

        // ── Status text with smooth slide + fade ──
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

        // ── "Stop searching" cancel button ──
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
                    'Stop searching',
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
      'signal',
      'frequency',
      'wavelength',
      'matches',
      'Finalizing',
    };
    final words = text.split(' ');
    return TextSpan(
      children: words.asMap().entries.map((entry) {
        final i = entry.key;
        final w = entry.value;
        final clean = w.replaceAll(RegExp(r'[^a-zA-Z]'), '');
        final isHighlight = keywords.contains(clean);
        return TextSpan(
          text: '${i > 0 ? ' ' : ''}$w',
          style: isHighlight
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
//  CUSTOM PAINTER
// ─────────────────────────────────────────────

class _FrequencyPainter extends CustomPainter {
  final int elapsed;
  final Color primary;
  static final Random _rng = Random(42);
  static List<_Particle>? _particles;

  _FrequencyPainter({required this.elapsed, required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.45;
    final t = elapsed.toDouble();

    _drawParticles(canvas, size, t);
    _drawAmbientGlow(canvas, cx, cy);
    _drawSonarRings(canvas, cx, cy, t);
    _drawCandidateWaves(canvas, cx, cy, t);
    _drawMainWave(canvas, cx, cy, t);
  }

  void _drawParticles(Canvas canvas, Size size, double t) {
    _particles ??= List.generate(
      30,
      (_) => _Particle(
        x: _rng.nextDouble() * 430,
        y: _rng.nextDouble() * 900,
        r: _rng.nextDouble() * 2.0 + 0.6,
        speed: _rng.nextDouble() * 0.15 + 0.05,
        phase: _rng.nextDouble() * pi * 2,
        opacity: _rng.nextDouble() * 0.25 + 0.06,
      ),
    );

    final paint = Paint();
    for (final p in _particles!) {
      final px = (p.x + sin(t * 0.0008 + p.phase) * 12) % size.width;
      final py = (p.y + t * p.speed * 0.06) % size.height;

      paint
        ..color = primary.withValues(alpha: p.opacity * 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(px, py), p.r * 2.5, paint);

      paint
        ..color = primary.withValues(alpha: p.opacity)
        ..maskFilter = null;
      canvas.drawCircle(Offset(px, py), p.r, paint);
    }
  }

  void _drawAmbientGlow(Canvas canvas, double cx, double cy) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          primary.withValues(alpha: 0.04),
          primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 200));
    canvas.drawCircle(Offset(cx, cy), 200, paint);
  }

  void _drawSonarRings(Canvas canvas, double cx, double cy, double t) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 0; i < 3; i++) {
      final cycle = ((t + i * 1100) % 3300) / 3300;
      final radius = 30 + cycle * 160;
      final alpha = (1 - cycle) * 0.12;
      if (alpha <= 0) continue;
      ringPaint.color = primary.withValues(alpha: alpha);
      canvas.drawCircle(Offset(cx, cy), radius, ringPaint);
    }
  }

  void _drawCandidateWaves(Canvas canvas, double cx, double cy, double t) {
    final configs = [
      _CandWave(delay: 2000, freq: 0.9, amp: 20, yOff: -35, isMatch: false),
      _CandWave(delay: 4000, freq: 1.6, amp: 18, yOff: 30, isMatch: false),
      _CandWave(delay: 6000, freq: 1.1, amp: 22, yOff: -20, isMatch: true),
      _CandWave(delay: 9000, freq: 1.3, amp: 25, yOff: 15, isMatch: true),
      _CandWave(delay: 11000, freq: 0.8, amp: 15, yOff: -40, isMatch: false),
      _CandWave(delay: 13000, freq: 1.15, amp: 20, yOff: 10, isMatch: true),
    ];

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final cw in configs) {
      final age = elapsed - cw.delay;
      if (age < 0) continue;

      double opacity;
      double drift = 0;

      if (cw.isMatch) {
        opacity = (age / 800.0).clamp(0, 1) * 0.3;
      } else {
        opacity = (age / 800.0).clamp(0, 1);
        if (age > 2500) {
          final fadeAge = age - 2500;
          opacity = (1 - fadeAge / 2000.0).clamp(0, 1);
          drift = fadeAge * 0.04 * (cw.yOff > 0 ? 1 : -1);
        }
        opacity *= 0.12;
      }
      if (opacity <= 0.01) continue;

      wavePaint
        ..color = cw.isMatch
            ? primary.withValues(alpha: opacity)
            : Colors.white.withValues(alpha: opacity)
        ..strokeWidth = cw.isMatch ? 1.2 : 0.7;

      final path = Path();
      const halfW = 150.0;
      for (double x = -halfW; x <= halfW; x += 2) {
        final norm = x / halfW;
        final env = cos(norm * pi / 2);
        final v =
            sin(norm * pi * 2 * cw.freq + t * 0.003 + cw.yOff) * cw.amp * env;
        final px = cx + x + drift;
        final py = cy + cw.yOff + v;
        if (x == -halfW) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      canvas.drawPath(path, wavePaint);
    }
  }

  void _drawMainWave(Canvas canvas, double cx, double cy, double t) {
    const freq = 1.2;
    const halfW = 170.0;
    final amp = 32.0 + sin(t * 0.001) * 4;

    final layers = [(8.0, 0.03), (4.0, 0.09), (2.2, 0.18), (1.6, 0.80)];

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final (w, a) in layers) {
      wavePaint
        ..strokeWidth = w
        ..color = primary.withValues(alpha: a);

      if (w > 4) {
        wavePaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      } else {
        wavePaint.maskFilter = null;
      }

      final path = Path();
      for (double x = -halfW; x <= halfW; x += 1.5) {
        final norm = x / halfW;
        final env = cos(norm * pi / 2);
        final v =
            (sin(norm * pi * 2 * freq + t * 0.003) * amp +
                sin(norm * pi * 2 * freq * 2.1 + t * 0.005 + 1.2) * amp * 0.25 +
                sin(norm * pi * 2 * freq * 0.5 + t * 0.0018 - 0.7) *
                    amp *
                    0.4) *
            env;
        final px = cx + x;
        final py = cy + v;
        if (x == -halfW) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FrequencyPainter oldDelegate) =>
      oldDelegate.elapsed != elapsed;
}

// ─────────────────────────────────────────────
//  DATA CLASSES
// ─────────────────────────────────────────────

class _Particle {
  final double x, y, r, speed, phase, opacity;
  const _Particle({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.phase,
    required this.opacity,
  });
}

class _CandWave {
  final int delay;
  final double freq, amp, yOff;
  final bool isMatch;
  const _CandWave({
    required this.delay,
    required this.freq,
    required this.amp,
    required this.yOff,
    required this.isMatch,
  });
}

// ─────────────────────────────────────────────
//  ERROR STATE
// ─────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const _ErrorBody({
    required this.message,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 48),
          const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyPrimary.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GreenButton(
            text: AppStrings.collab.retry,
            height: 52,
            onPressed: onRetry,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onCancel,
            child: Text(
              'Go back',
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
