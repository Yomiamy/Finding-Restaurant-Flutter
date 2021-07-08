import 'package:flutter/material.dart';
import 'package:flutter_restaruant/utils/Dimens.dart';

class EmptyDataWidget extends StatelessWidget {
  const EmptyDataWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
      child: Text("No Data.",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize:  Dimens.xxxhFontSize)
      )
  );
}
