import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../features/foundation/style/style_barrel.dart';

class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(ThemeSize.radius8),
    ),
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    // using Theme colors instead of hardcoded Colors.grey
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
