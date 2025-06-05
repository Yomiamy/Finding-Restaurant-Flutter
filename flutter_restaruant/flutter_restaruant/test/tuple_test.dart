import 'package:flutter_restaruant/utils/Tuple.dart';
import 'package:flutter_test/flutter_test.dart';

main() {
  group("Tuple testing group", () {
    test("Tuple2 test key-value", () {
      String str1 = "str1";
      String str2 = "str2";
      final stringTuple2 = Tuple2<String, String>(str1, str2);

      expect(stringTuple2.item1, str1);
      expect(stringTuple2.item2, str2);
    });

    test("Tuple3 test key-value", () {
      String str1 = "str1";
      String str2 = "str2";
      String str3 = "str3";
      final stringTuple2 = Tuple3<String, String, String>(str1, str2, str3);

      expect(stringTuple2.item1, str1);
      expect(stringTuple2.item2, str2);
      expect(stringTuple2.item3, str3);
    });

    test("Tuple test null item", () {
      final nullItemTuple2 = Tuple2<dynamic, dynamic>(null, null);
      expect(nullItemTuple2.item1, null);
      expect(nullItemTuple2.item2, null);

      final nullItemTuple = Tuple3<dynamic, dynamic, dynamic>(null, null, null);

      expect(nullItemTuple.item1, null);
      expect(nullItemTuple.item2, null);
      expect(nullItemTuple.item3, null);
    });
  });
}
