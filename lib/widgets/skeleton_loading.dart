import 'package:flutter/material.dart';

/// Shimmer effect wrapper for skeleton loading animations
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            final slidePercent = _controller.value;
            return LinearGradient(
              colors: isDark
                  ? [
                      Colors.grey[800]!,
                      Colors.grey[600]!,
                      Colors.grey[800]!
                    ]
                  : [
                      Colors.grey[300]!,
                      Colors.grey[100]!,
                      Colors.grey[300]!
                    ],
              stops: [
                (slidePercent - 0.3).clamp(0.0, 1.0),
                slidePercent,
                (slidePercent + 0.3).clamp(0.0, 1.0),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton box placeholder - rectangular shape
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ShimmerEffect(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[700] : Colors.grey[300],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton circle for avatars
class SkeletonCircle extends StatelessWidget {
  final double size;
  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ShimmerEffect(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[700] : Colors.grey[300],
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Skeleton list tile (avatar + text lines) - for member/event cards
class SkeletonListTile extends StatelessWidget {
  final double avatarSize;
  final bool showSubtitle;

  const SkeletonListTile({
    super.key,
    this.avatarSize = 40,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          SkeletonCircle(size: avatarSize),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: double.infinity, height: 14),
                if (showSubtitle) ...[
                  const SizedBox(height: 8),
                  SkeletonBox(width: 150, height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton dialog content (multiple list tiles)
class SkeletonDialogContent extends StatelessWidget {
  final int itemCount;
  final bool showSubtitles;

  const SkeletonDialogContent({
    super.key,
    this.itemCount = 3,
    this.showSubtitles = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        itemCount,
        (index) => SkeletonListTile(showSubtitle: showSubtitles),
      ),
    );
  }
}

/// Skeleton for profile dialog
class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          const SkeletonCircle(size: 80),
          const SizedBox(height: 16),
          // Name
          const SkeletonBox(width: 200, height: 20),
          const SizedBox(height: 8),
          // Email
          const SkeletonBox(width: 150, height: 14),
          const SizedBox(height: 24),
          // Form fields
          const SkeletonBox(width: double.infinity, height: 48),
          const SizedBox(height: 12),
          const SkeletonBox(width: double.infinity, height: 48),
          const SizedBox(height: 12),
          const SkeletonBox(width: double.infinity, height: 48),
        ],
      ),
    );
  }
}

/// Skeleton for cards with header and content
class SkeletonCard extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonCard({
    super.key,
    this.width = double.infinity,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 120, height: 16),
          const SizedBox(height: 8),
          const Expanded(child: SkeletonBox(width: double.infinity, height: 40)),
        ],
      ),
    );
  }
}

/// Skeleton for group list items
class SkeletonGroupCard extends StatelessWidget {
  const SkeletonGroupCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonCircle(size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonBox(width: 150, height: 16),
                      const SizedBox(height: 4),
                      SkeletonBox(width: 100, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SkeletonBox(width: double.infinity, height: 32),
          ],
        ),
      ),
    );
  }
}
