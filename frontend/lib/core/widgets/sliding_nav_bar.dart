import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/app_haptics.dart';

// ── Configurable values ────────────────────────────────────

const double kNavBarHeight = 91;
const double kNavBarTopPadding = 6;
const double kNavBarBottomPadding = 16;
const double kButtonHeight = 68;
const double kIconBackdropSize = 56;
const double kUpperCardHeight = 64;
const double kLowerCardHeight = 56;
const double kLowerCardOffsetY = 38;
const double kDotSize = 5;
const double kDotOffsetY = 22;

const double kTitleFontSize = 12;
const FontWeight kTitleFontWeight = FontWeight.w500;

// [FIXED] Slower duration for a more relaxed feel
const Duration kAnimDuration = Duration(milliseconds: 600);

// [FIXED] Unified smooth curve to eliminate the "bouncing" visual
const Curve kSmoothCurve = Curves.easeInOutCubic;
const Interval kMainInterval = Interval(0.0, 1.0, curve: kSmoothCurve);

const Offset kIconSlideEnd = Offset(0, -1.4);
const Offset kCardSlideBegin = Offset(0, 0.8);
const Offset kCardSlideEnd = Offset(0, -0.8);
const Offset kTitleSlideBegin = Offset(0, 1.6);

const double kCardFractionBegin = 0.1;
const double kCardFractionEnd = 0.4;

// ── Public API ─────────────────────────────────────────────

class SlidingNavItem {
  final Widget icon;
  final String title;

  const SlidingNavItem({required this.icon, required this.title});
}

class SlidingNavBar extends StatelessWidget {
  final List<SlidingNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  final Color backgroundColor;
  final Color activeColor;
  final Color inactiveColor;

  const SlidingNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    this.backgroundColor = AppColors.cardFront,
    this.activeColor = AppColors.primary,
    this.inactiveColor = AppColors.textWhite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kNavBarHeight,
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.only(
        top: kNavBarTopPadding,
        bottom: kNavBarBottomPadding,
      ),
      decoration: const ShapeDecoration(
        color: AppColors.cardFront,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        shadows: [
          BoxShadow(
            color: AppColors.background,
            blurRadius: 62,
            offset: Offset(0, -6),
            spreadRadius: 0,
          ),
        ],
      ),
      // Keeps the top border perfectly visible above the sliding masks
      foregroundDecoration: const ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: AppColors.outline),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          return Expanded(
            child: _SlidingNavButton(
              item: items[i],
              isSelected: i == selectedIndex,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              backgroundColor: backgroundColor,
              onTap: () => onTap(i),
              itemCount: items.length,
            ),
          );
        }),
      ),
    );
  }
}

// ── Animated Button Widget ─────────────────────────────────

class _SlidingNavButton extends StatefulWidget {
  final SlidingNavItem item;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final Color backgroundColor;
  final VoidCallback onTap;
  final int itemCount;

  const _SlidingNavButton({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.backgroundColor,
    required this.onTap,
    required this.itemCount,
  });

  @override
  State<_SlidingNavButton> createState() => _SlidingNavButtonState();
}

class _SlidingNavButtonState extends State<_SlidingNavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: kAnimDuration);
    if (widget.isSelected) _controller.forward(from: 1.0);
  }

  @override
  void didUpdateWidget(_SlidingNavButton old) {
    super.didUpdateWidget(old);
    if (old.isSelected != widget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemWidth = MediaQuery.of(context).size.width / widget.itemCount;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AppHaptics.uiTap();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) {
          // Both the slide and the shape morph now use the exact same smooth timing
          final slide = CurvedAnimation(
            parent: _controller,
            curve: kMainInterval,
          );

          final cardFraction = Tween<double>(
            begin: kCardFractionBegin,
            end: kCardFractionEnd,
          ).animate(slide).value;

          return SizedBox(
            height: kButtonHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  color: widget.backgroundColor,
                  width: kIconBackdropSize,
                  height: kIconBackdropSize,
                ),
                SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset.zero,
                    end: kIconSlideEnd,
                  ).animate(slide),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      widget.inactiveColor,
                      BlendMode.srcIn,
                    ),
                    child: widget.item.icon,
                  ),
                ),
                SlideTransition(
                  position: Tween<Offset>(
                    begin: kCardSlideBegin,
                    end: kCardSlideEnd,
                  ).animate(slide),
                  child: _SlicedCard(
                    color: widget.backgroundColor,
                    heightFraction: cardFraction,
                    width: itemWidth,
                    height: kUpperCardHeight,
                  ),
                ),
                SlideTransition(
                  position: Tween<Offset>(
                    begin: kTitleSlideBegin,
                    end: Offset.zero,
                  ).animate(slide),
                  child: Text(
                    widget.item.title,
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: kTitleFontSize,
                      fontWeight: kTitleFontWeight,
                      color: widget.activeColor,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, kLowerCardOffsetY),
                  child: _SlicedCard(
                    color: widget.backgroundColor,
                    heightFraction: cardFraction,
                    width: itemWidth,
                    height: kLowerCardHeight,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, kDotOffsetY),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.0, end: 1.0).animate(slide),
                    child: Container(
                      width: kDotSize,
                      height: kDotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.activeColor,
                      ),
                    ),
                  ),
                ),
                // Ripple effect completely removed
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Custom painters [Optimized] ────────────────────────────

class _SlicedCard extends StatelessWidget {
  final Color color;
  final double heightFraction;
  final double width;
  final double height;

  const _SlicedCard({
    required this.color,
    required this.heightFraction,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _SlicedCardPainter(color, heightFraction)),
    );
  }
}

class _SlicedCardPainter extends CustomPainter {
  final Color color;
  final double heightPercent;
  final Paint _paint;

  _SlicedCardPainter(this.color, this.heightPercent)
    : _paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..lineTo(size.width, size.height * heightPercent)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(covariant _SlicedCardPainter old) =>
      old.heightPercent != heightPercent || old.color != color;
}
