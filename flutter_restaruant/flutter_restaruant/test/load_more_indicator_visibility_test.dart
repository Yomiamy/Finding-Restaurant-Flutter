import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 鎖住 load-more indicator 的「可見性」回歸。
///
/// 症狀：滑到最底觸發載入更多時，indicator 有被 build 出來，但因為它是被追加在
/// 目前捲動底部「之下」的新內容，viewport 仍停在舊的 maxScrollExtent，
/// 使用者完全看不到轉圈圈。
///
/// 這裡用與 RestaurantInfoListWidget 相同的 itemCount / index 結構做對照組與
/// 實驗組，避免測試被 BannerAD 與 MainBloc 的相依性拖累。
class _WithoutReveal extends StatelessWidget {
  final ScrollController _scrollController = ScrollController();
  final int _count;
  final bool _isLoadingMore;

  _WithoutReveal(this._count, {bool isLoadingMore = false})
    : _isLoadingMore = isLoadingMore;

  @override
  Widget build(BuildContext context) =>
      _buildList(_scrollController, _count, isLoadingMore: _isLoadingMore);
}

class _WithReveal extends StatefulWidget {
  final int count;
  final bool isLoadingMore;

  const _WithReveal(this.count, {this.isLoadingMore = false});

  @override
  State<_WithReveal> createState() => _WithRevealState();
}

class _WithRevealState extends State<_WithReveal> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(_WithReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isLoadingMore && widget.isLoadingMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildList(
    _scrollController,
    widget.count,
    isLoadingMore: widget.isLoadingMore,
  );
}

Widget _buildList(
  ScrollController controller,
  int count, {
  required bool isLoadingMore,
}) {
  return ListView.builder(
    controller: controller,
    itemCount: count + 2 + (isLoadingMore ? 1 : 0),
    itemBuilder: (context, index) {
      if (index == 0) return const SizedBox(height: 60, child: Text('banner'));
      if (index == 1) return const SizedBox(height: 60, child: Text('tags'));
      if (index == count + 2) {
        return const SizedBox(
          height: 60,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return SizedBox(height: 60, child: Text('item${index - 2}'));
    },
  );
}

Future<void> _scrollToBottom(WidgetTester tester) async {
  await tester.fling(find.byType(ListView), const Offset(0, -5000), 3000);
  await tester.pumpAndSettle();
}

/// CircularProgressIndicator 會無限動畫，pumpAndSettle 會 timeout，改用定量 pump。
Future<void> _enterLoading(WidgetTester tester, Widget next) async {
  await tester.pumpWidget(next);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('對照組：不捲動露出時，indicator 建出來了卻在 viewport 之外', (tester) async {
    Widget host({required bool loading}) => MaterialApp(
      home: Scaffold(body: _WithoutReveal(20, isLoadingMore: loading)),
    );

    await tester.pumpWidget(host(loading: false));
    await _scrollToBottom(tester);
    await _enterLoading(tester, host(loading: true));

    expect(
      find.byType(CircularProgressIndicator, skipOffstage: false),
      findsOneWidget,
      reason: 'indicator 應該有被 build',
    );
    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: '這正是回歸症狀：build 了但看不到',
    );
  });

  testWidgets('修正後：進入載入態會把 indicator 捲進畫面', (tester) async {
    Widget host({required bool loading}) => MaterialApp(
      home: Scaffold(body: _WithReveal(20, isLoadingMore: loading)),
    );

    await tester.pumpWidget(host(loading: false));
    await _scrollToBottom(tester);
    await _enterLoading(tester, host(loading: true));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
