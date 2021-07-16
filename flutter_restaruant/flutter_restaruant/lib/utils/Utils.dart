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
}
