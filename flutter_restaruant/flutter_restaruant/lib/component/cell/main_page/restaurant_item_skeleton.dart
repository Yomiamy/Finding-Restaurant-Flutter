import 'package:flutter/material.dart';
import '../../skeleton.dart';
import '../../../features/foundation/style/style_barrel.dart';

class RestaurantItemSkeleton extends StatelessWidget {
  const RestaurantItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: ThemeSize.restaurantItemImageSize,
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
            Skeleton(
              width: ThemeSize.restaurantItemImageSize,
              height: ThemeSize.restaurantItemImageSize,
            ),
            SizedBox(width: ThemeSize.space10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Skeleton(
                    width: double.infinity,
                    height: ThemeSize.skeletonTextHeightLg,
                  ),
                  Skeleton(
                    width: ThemeSize.skeletonTextWidthLg,
                    height: ThemeSize.skeletonTextHeightMd,
                  ),
                  Skeleton(
                    width: double.infinity,
                    height: ThemeSize.skeletonTextHeightMd,
                  ),
                  Skeleton(
                    width: ThemeSize.skeletonTextWidthMd,
                    height: ThemeSize.skeletonTextHeightMd,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
