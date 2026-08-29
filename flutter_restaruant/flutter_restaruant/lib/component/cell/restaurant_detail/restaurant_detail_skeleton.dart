import 'package:flutter/material.dart';

import '../../../features/foundation/style/style_barrel.dart';
import '../../skeleton.dart';

/// 餐廳詳情頁的載入骨架。
///
/// 各區塊的尺寸刻意對齊真實 cell（頁首圖 220、地圖 140、相片條
/// `寬/3.2`、留言頭像 64），讓資料載入完成時版面不會跳動。改動任一
/// cell 的尺寸時，這裡要跟著改。
class RestaurantDetailSkeleton extends StatelessWidget {
  const RestaurantDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double photoSize = screenWidth / 3.2;

    return ListView(
      // 骨架僅供展示，讓它不可捲動以免使用者「滑動」一個空殼。
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        // 頁首大圖
        Skeleton(
          width: screenWidth,
          height: ThemeSize.size220,
          borderRadius: BorderRadius.zero,
        ),
        // 資訊區：左側靜態地圖 + 右側文字
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeSize.space12,
            vertical: ThemeSize.space10,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Skeleton(
                width: ThemeSize.size140,
                height: ThemeSize.size140,
              ),
              const SizedBox(width: ThemeSize.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Skeleton(
                      width: screenWidth,
                      height: ThemeSize.size16,
                    ),
                    const SizedBox(height: ThemeSize.space8),
                    const Skeleton(
                      width: ThemeSize.size120,
                      height: ThemeSize.size14,
                    ),
                    const SizedBox(height: ThemeSize.space8),
                    const Skeleton(
                      width: ThemeSize.size80,
                      height: ThemeSize.size14,
                    ),
                    const SizedBox(height: ThemeSize.space8),
                    const Skeleton(
                      width: ThemeSize.size100,
                      height: ThemeSize.size14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // 相片橫向捲軸
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeSize.space12,
            vertical: ThemeSize.space8,
          ),
          // 與 RestaurantImageCell 一樣是橫向捲軸——用 Row 會因為
          // 三格加間距超出可用寬度而 overflow。
          child: SizedBox(
            height: photoSize,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(right: ThemeSize.space8),
                child: Skeleton(width: photoSize, height: photoSize),
              ),
            ),
          ),
        ),
        // 營業時間卡片
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ThemeSize.space12,
            vertical: ThemeSize.space8,
          ),
          child: Skeleton(width: double.infinity, height: ThemeSize.size200),
        ),
        // 留言列表
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeSize.space12,
            vertical: ThemeSize.space8,
          ),
          child: Column(
            children: List<Widget>.generate(
              2,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: ThemeSize.space12),
                child: _CommentSkeleton(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 單則留言的骨架：左側頭像、右側三行文字。
class _CommentSkeleton extends StatelessWidget {
  const _CommentSkeleton();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Skeleton(width: ThemeSize.size64, height: ThemeSize.size64),
      const SizedBox(width: ThemeSize.space12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Skeleton(
              width: ThemeSize.size120,
              height: ThemeSize.size14,
            ),
            const SizedBox(height: ThemeSize.space8),
            Skeleton(
              width: MediaQuery.sizeOf(context).width,
              height: ThemeSize.size14,
            ),
            const SizedBox(height: ThemeSize.space8),
            const Skeleton(
              width: ThemeSize.size80,
              height: ThemeSize.size14,
            ),
          ],
        ),
      ),
    ],
  );
}
