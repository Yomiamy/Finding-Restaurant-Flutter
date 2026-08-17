import 'package:flutter/material.dart';
import '../features/foundation/style/style_barrel.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    // Rating star usually uses Amber or primary color; using primary to fit the theme
    final color = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (rating >= index + 1) {
          return Icon(Icons.star, size: ThemeSize.size16, color: color);
        } else if (rating >= index + 0.5) {
          return Icon(Icons.star_half, size: ThemeSize.size16, color: color);
        } else {
          return Icon(Icons.star_border, size: ThemeSize.size16, color: color);
        }
      }),
    );
  }
}
