import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 驗證各處 imageErrorBuilder 的產出在其實際 layout 下不會撐爆父層。
///
/// 佔位圖 noImage 原始尺寸為 1280x960，未受約束時會以原尺寸佈局。
/// 這裡以「外層是否提供緊約束」重現各 cell 的實際處境。
void main() {
  // 無約束的 error widget 放進窄 Row —— restaurant_item_cell 的原始 bug 情境。
  testWidgets('未約束的 Image.asset 在窄 Row 中會溢出', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: Row(
              children: <Widget>[
                _BigImageStub(),
                Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNotNull, reason: '未約束應溢出');
  });

  // comment/info cell 的處境：FadeInImage 外層已有 SizedBox 緊約束。
  testWidgets('SizedBox 包住時 error widget 受約束而不溢出', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 100,
                  height: 100,
                  child: _BigImageStub(),
                ),
                Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(_BigImageStub)).width, 100);
  });
}

/// 模擬 noImage 佔位圖在真機上的原始尺寸 (1280x960)。
/// widget test 載入的資產是 1x1 佔位，無法重現尺寸溢出，故以此替代。
class _BigImageStub extends StatelessWidget {
  const _BigImageStub();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 1280, height: 960);
}
