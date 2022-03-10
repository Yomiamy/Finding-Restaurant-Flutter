import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class Utils {
  static String? encodeQueryParameters(Map<String, String> params) => params
      .entries
      .map((e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');

  static void openUrl({ required String scheme,
    required String host, String path = "",
    Map<String, String> parameters = const <String, String>{}}) async {

    final Uri uri = Uri(
      scheme: scheme,
      host: host,
      path: path,
      query: encodeQueryParameters(parameters),
    );

    bool isCanLaunch = await canLaunch(uri.toString());
    if(isCanLaunch) {
      launch(uri.toString());
    }
  }

  static Future<Position> getCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      throw Exception('Location permissions are permanently denied, we cannot request permissions.');
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
}
