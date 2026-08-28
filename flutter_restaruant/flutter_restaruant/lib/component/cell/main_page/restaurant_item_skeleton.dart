import 'package:flutter/material.dart';
import '../../skeleton.dart';
import '../../../features/foundation/style/style_barrel.dart';

class RestaurantItemSkeleton extends StatelessWidget {
  const RestaurantItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ThemeSize.size120,
      child: Padding(
        padding: const EdgeInsets.only(
          left: ThemeSize.space10,
          right: ThemeSize.space5,
          top: ThemeSize.space10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Skeleton(width: ThemeSize.size110, height: ThemeSize.size110),
            const SizedBox(width: ThemeSize.space10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Skeleton(
                    width: MediaQuery.of(context).size.width,
                    height: ThemeSize.skeletonTextHeightLg,
                  ),
                  const Skeleton(
                    width: ThemeSize.skeletonTextWidthLg,
                    height: ThemeSize.skeletonTextHeightMd,
                  ),
                  Skeleton(
                    width: MediaQuery.of(context).size.width,
                    height: ThemeSize.skeletonTextHeightMd,
                  ),
                  const Skeleton(
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
