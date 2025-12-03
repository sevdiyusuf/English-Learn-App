import 'package:flutter/material.dart';

/// Skeleton loading widget with shimmer effect
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    this.width,
    this.height,
    this.borderRadius,
    super.key,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Shimmer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

/// Shimmer effect widget
class Shimmer extends StatefulWidget {
  const Shimmer({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.transparent,
                Colors.white54,
                Colors.transparent,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Card skeleton for room/game cards
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoadingSkeleton(
              width: double.infinity,
              height: 20,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            LoadingSkeleton(
              width: 150,
              height: 16,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            LoadingSkeleton(
              width: 100,
              height: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

/// List skeleton for loading lists
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({
    this.itemCount = 3,
    super.key,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CardSkeleton(),
        );
      },
    );
  }
}

/// Page skeleton for full page loading
class PageSkeleton extends StatelessWidget {
  const PageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingSkeleton(
            width: 200,
            height: 24,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListSkeleton(itemCount: 5),
          ),
        ],
      ),
    );
  }
}

/// Game page skeleton
class GamePageSkeleton extends StatelessWidget {
  const GamePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timer skeleton
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  LoadingSkeleton(
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LoadingSkeleton(
                          width: 100,
                          height: 16,
                        ),
                        const SizedBox(height: 8),
                        LoadingSkeleton(
                          width: double.infinity,
                          height: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  LoadingSkeleton(
                    width: 50,
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Players skeleton
          LoadingSkeleton(
            width: double.infinity,
            height: 80,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 16),
          // Input skeleton
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  LoadingSkeleton(
                    width: double.infinity,
                    height: 48,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 16),
                  LoadingSkeleton(
                    width: double.infinity,
                    height: 48,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

