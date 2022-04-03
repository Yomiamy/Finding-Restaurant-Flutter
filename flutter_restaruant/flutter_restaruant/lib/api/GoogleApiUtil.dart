import 'package:sprintf/sprintf.dart';
import '../utils/Constants.dart';

class GoogleApiUtil {
  static String createStaticMapUrl({ required double lat, 
    required double lng, 
    int w = 200,
    int h = 200 }) {
    String centerLatLngStr = sprintf("%f,%f", [lat, lng]);
    return "${Constants.GOOGLE_STATIC_MAP}?center=${centerLatLngStr}&&markers=color:red%7Clabel:S%7C${centerLatLngStr}&size=${w}x${h}&scale=2&zoom=16&language=zh-TW&key=${Constants.STATIC_MAP_API_KEY}";
  }
}