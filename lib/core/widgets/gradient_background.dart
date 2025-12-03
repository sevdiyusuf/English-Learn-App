import 'package:flutter/material.dart';

/// Background widget with image
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}

