import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.starSize = 16.0,
    this.color = Colors.amber,
  });

  final double rating;
  final double starSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (rating >= index + 1) {
          return Icon(Icons.star, size: starSize, color: color);
        } else if (rating >= index + 0.5) {
          return Icon(Icons.star_half, size: starSize, color: color);
        } else {
          return Icon(Icons.star_border, size: starSize, color: color);
        }
      }),
    );
  }
}
