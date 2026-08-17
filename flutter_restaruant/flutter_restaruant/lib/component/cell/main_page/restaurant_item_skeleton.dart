import 'package:flutter/material.dart';
import '../../skeleton.dart';
import '../../../features/foundation/style/style_barrel.dart';

class RestaurantItemSkeleton extends StatelessWidget {
  const RestaurantItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 110,
      child: Padding(
        padding: EdgeInsets.only(
          left: ThemeSize.space10,
          right: ThemeSize.space5,
          top: ThemeSize.space10,
          bottom: ThemeSize.zero,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(width: 110, height: 110),
            SizedBox(width: ThemeSize.space10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Skeleton(width: double.infinity, height: 16),
                  Skeleton(width: 120, height: 14),
                  Skeleton(width: double.infinity, height: 14),
                  Skeleton(width: 80, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
