for file in flutter_restaruant/flutter_restaruant/test/flow/ai_foodie/ai_foodie_bloc_test.dart flutter_restaruant/flutter_restaruant/test/flow/menu_vision/menu_vision_bloc_test.dart flutter_restaruant/flutter_restaruant/test/flow/menu_vision/menu_vision_sheet_test.dart; do
  sed -i '' 's/setUp(() {/setUp(() async {\n    await S.load(const Locale('\''zh'\'', '\''TW'\''));/g' $file
  # Also need to import S
  sed -i '' '1i\
import '\''package:flutter_restaruant/generated/l10n.dart'\'';\
import '\''package:flutter/material.dart'\'';
' $file
done
