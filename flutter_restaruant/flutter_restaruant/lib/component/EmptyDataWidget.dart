import 'package:flutter/material.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';

class EmptyDataWidget extends StatelessWidget {
  const EmptyDataWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
      child: Text("目前無任何資料",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize:  UIConstants.xxxhFontSize)
      )
  );
}
