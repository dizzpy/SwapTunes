import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  SwapTunes — Wavy Progress Indicator Widget
//  Reusable drop-in replacement for LinearProgressIndicator
//  Matches M3 Expressive spec (wavy indeterminate shape)
// ─────────────────────────────────────────────

/// A reusable wavy linear progress indicator styled for SwapTunes.
///
/// Usage:
///   WavyProgressIndicator()                              // indeterminate
///   WavyProgressIndicator(value: 0.6)                   // determinate 60%
///   WavyProgressIndicator(waveCount: 5, speed: 800)     // 5 waves, faster
///   WavyProgressIndicator(strokeCap: StrokeCap.square)  // flat ends
///   WavyProgressIndicator(showTrack: false)              // no background track
///   WavyProgressIndicator(segmentWidthFactor: 0.7)      // wider sliding segment
class WavyProgressIndicator extends StatefulWidget {
  /// 0.0–1.0 for determinate, null for indeterminate (animated).
  final double? value;

  /// Active track color. Defaults to theme primary.
  final Color? color;

  /// Background track color.
  final Color? backgroundColor;

  /// Height of the indicator track. Default is 4dp (M3 standard).
  final double height;

  /// Wave amplitude — how tall the waves are. Default 3.
  final double amplitude;

  /// Wavelength in logical pixels. Default 20.
  /// Lower = more tightly packed waves. Use [waveCount] for a simpler control.
  final double wavelength;

  /// Number of full waves visible across the widget width.
  /// When set, overrides [wavelength] automatically based on widget size.
  /// Default null (uses [wavelength] directly).
  final int? waveCount;

  /// Animation cycle duration in milliseconds. Default 1200.
  final int speed;

  /// End-cap style for the wave stroke. Default [StrokeCap.round].
  final StrokeCap strokeCap;

  /// For indeterminate mode — fraction of the track width that the
  /// sliding segment occupies (0.1–1.0). Default 0.55.
  final double segmentWidthFactor;

  /// Whether to render the background flat track. Default true.
  final bool showTrack;

  const WavyProgressIndicator({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
    this.height = 4.0,
    this.amplitude = 3.0,
    this.wavelength = 20.0,
    this.waveCount,
    this.speed = 1200,
    this.strokeCap = StrokeCap.round,
    this.segmentWidthFactor = 0.55,
    this.showTrack = true,
  });

  @override
  State<WavyProgressIndicator> createState() => _WavyProgressIndicatorState();
}

class _WavyProgressIndicatorState extends State<WavyProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.speed),
    )..repeat();
  }

  @override
  void didUpdateWidget(WavyProgressIndicator old) {
    super.didUpdateWidget(old);
    if (old.speed != widget.speed) {
      _controller.duration = Duration(milliseconds: widget.speed);
      _controller
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.color ?? Theme.of(context).colorScheme.primary;
    final trackColor = widget.backgroundColor ?? activeColor.withOpacity(0.2);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Resolve effective wavelength from waveCount if provided.
        final effectiveWavelength = widget.waveCount != null
            ? constraints.maxWidth / widget.waveCount!
            : widget.wavelength;

        return SizedBox(
          height: widget.height + widget.amplitude * 2,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _WavyPainter(
                  value: widget.value,
                  animationValue: _controller.value,
                  activeColor: activeColor,
                  trackColor: trackColor,
                  amplitude: widget.amplitude,
                  wavelength: effectiveWavelength,
                  strokeWidth: widget.height,
                  strokeCap: widget.strokeCap,
                  segmentWidthFactor: widget.segmentWidthFactor.clamp(0.1, 1.0),
                  showTrack: widget.showTrack,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _WavyPainter extends CustomPainter {
  final double? value;
  final double animationValue;
  final Color activeColor;
  final Color trackColor;
  final double amplitude;
  final double wavelength;
  final double strokeWidth;
  final StrokeCap strokeCap;
  final double segmentWidthFactor;
  final bool showTrack;

  _WavyPainter({
    required this.value,
    required this.animationValue,
    required this.activeColor,
    required this.trackColor,
    required this.amplitude,
    required this.wavelength,
    required this.strokeWidth,
    required this.strokeCap,
    required this.segmentWidthFactor,
    required this.showTrack,
  });

  Path _buildWavePath(
    double startX,
    double endX,
    double centerY,
    double phase,
  ) {
    final path = Path();
    path.moveTo(startX, centerY);
    for (double x = startX; x <= endX; x++) {
      final y =
          centerY +
          amplitude * math.sin((x / wavelength * 2 * math.pi) + phase);
      path.lineTo(x, y);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final phase = animationValue * 2 * math.pi;

    if (showTrack) {
      final trackPaint = Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..strokeCap = strokeCap
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(0, centerY),
        Offset(size.width, centerY),
        trackPaint,
      );
    }

    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = strokeCap
      ..style = PaintingStyle.stroke;

    if (value != null) {
      // ── Determinate mode ──
      final activeEnd = size.width * value!.clamp(0.0, 1.0);
      if (activeEnd > 0) {
        final activePath = _buildWavePath(0, activeEnd, centerY, phase);
        canvas.drawPath(activePath, activePaint);
      }
    } else {
      // ── Indeterminate mode — sliding wavy segment ──
      final segmentWidth = size.width * segmentWidthFactor;
      final offset =
          animationValue * (size.width + segmentWidth) - segmentWidth;
      final startX = offset.clamp(-segmentWidth, size.width);
      final endX = (offset + segmentWidth).clamp(0.0, size.width);

      if (endX > startX) {
        final wavePath = _buildWavePath(startX, endX, centerY, phase);

        // Fade in/out at edges using a shader.
        final shader = LinearGradient(
          colors: [
            activeColor.withOpacity(0.0),
            activeColor,
            activeColor,
            activeColor.withOpacity(0.0),
          ],
          stops: const [0.0, 0.15, 0.85, 1.0],
        ).createShader(Rect.fromLTWH(startX, 0, endX - startX, size.height));

        activePaint.shader = shader;
        canvas.drawPath(wavePath, activePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_WavyPainter old) =>
      old.animationValue != animationValue ||
      old.value != value ||
      old.wavelength != wavelength ||
      old.amplitude != amplitude ||
      old.strokeCap != strokeCap ||
      old.showTrack != showTrack ||
      old.segmentWidthFactor != segmentWidthFactor;
}

// ─────────────────────────────────────────────
//  Circular wavy variant (indeterminate only)
//  Mimics M3 Expressive circular wavy indicator
// ─────────────────────────────────────────────

/// A reusable wavy circular progress indicator.
///
/// Usage:
///   WavyCircularIndicator()
///   WavyCircularIndicator(waveCount: 12, amplitude: 3.0)
///   WavyCircularIndicator(arcFraction: 0.6, speed: 900)
///   WavyCircularIndicator(showTrack: false)
class WavyCircularIndicator extends StatefulWidget {
  /// Active stroke color. Defaults to theme primary.
  final Color? color;

  /// Background track ring color.
  final Color? backgroundColor;

  /// Diameter of the indicator. Default 40.
  final double size;

  /// Width of the stroke. Default 4.
  final double strokeWidth;

  /// Number of full sine-wave cycles along the arc. Default 8.
  final int waveCount;

  /// Wave amplitude as a multiplier of [strokeWidth].
  /// Higher = deeper waves. Default 0.6.
  final double amplitudeFactor;

  /// Fraction of the full circle that the arc spans (0.0–1.0).
  /// 1.0 = full 360°, 0.7 = 252° (default), 0.5 = half circle.
  final double arcFraction;

  /// Animation cycle duration in milliseconds. Default 1400.
  final int speed;

  /// Whether to render the background track ring. Default true.
  final bool showTrack;

  const WavyCircularIndicator({
    super.key,
    this.color,
    this.backgroundColor,
    this.size = 40.0,
    this.strokeWidth = 4.0,
    this.waveCount = 8,
    this.amplitudeFactor = 0.6,
    this.arcFraction = 0.7,
    this.speed = 1400,
    this.showTrack = true,
  });

  @override
  State<WavyCircularIndicator> createState() => _WavyCircularIndicatorState();
}

class _WavyCircularIndicatorState extends State<WavyCircularIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.speed),
    )..repeat();
  }

  @override
  void didUpdateWidget(WavyCircularIndicator old) {
    super.didUpdateWidget(old);
    if (old.speed != widget.speed) {
      _controller.duration = Duration(milliseconds: widget.speed);
      _controller
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.color ?? Theme.of(context).colorScheme.primary;
    final trackColor = widget.backgroundColor ?? activeColor.withOpacity(0.2);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _WavyCircularPainter(
            animationValue: _controller.value,
            activeColor: activeColor,
            trackColor: trackColor,
            strokeWidth: widget.strokeWidth,
            waveCount: widget.waveCount,
            amplitudeFactor: widget.amplitudeFactor,
            arcFraction: widget.arcFraction.clamp(0.05, 1.0),
            showTrack: widget.showTrack,
          ),
        ),
      ),
    );
  }
}

class _WavyCircularPainter extends CustomPainter {
  final double animationValue;
  final Color activeColor;
  final Color trackColor;
  final double strokeWidth;
  final int waveCount;
  final double amplitudeFactor;
  final double arcFraction;
  final bool showTrack;

  _WavyCircularPainter({
    required this.animationValue,
    required this.activeColor,
    required this.trackColor,
    required this.strokeWidth,
    required this.waveCount,
    required this.amplitudeFactor,
    required this.arcFraction,
    required this.showTrack,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;
    final amplitude = strokeWidth * amplitudeFactor;
    final phase = animationValue * 2 * math.pi;
    final arcOffset = animationValue * 2 * math.pi;
    final arcLength = 2 * math.pi * arcFraction;
    const steps = 120;

    if (showTrack) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = trackColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke,
      );
    }

    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = strokeWidth * 0.9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final angle = arcOffset + t * arcLength;
      final wave = amplitude * math.sin(t * waveCount * math.pi + phase);
      final r = radius + wave;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, activePaint);
  }

  @override
  bool shouldRepaint(_WavyCircularPainter old) =>
      old.animationValue != animationValue ||
      old.waveCount != waveCount ||
      old.amplitudeFactor != amplitudeFactor ||
      old.arcFraction != arcFraction ||
      old.showTrack != showTrack;
}
