import 'package:flutter/cupertino.dart';

class Constants {
  static const EmptyWidget = SizedBox(height: 0);

  /// [String]
  static const APP_TITLE = "尋找餐廳";
  static const LOGIN_TITLE = "登入頁";

  /// [API]
  static const BASE_URL = "https://api.yelp.com";
  static const GOOGLE_MAP_API_URL = "https://maps.googleapis.com/maps/api";
  static const GOOGLE_STATIC_MAP = "$GOOGLE_MAP_API_URL/staticmap";
  static const HTTPS_SCHEME = "https";
  static const GOOGLE_MAP_HOST = "maps.google.de";
  static const GOOGLE_MAP_NAVIGATION_PATH = "/maps";
  static const GOOGLE_MAP_NAVIGATION_LATLNG = "q";
  static const GOOGLE_MAP_STREETVIEW_LAYER = "layer";
  static const GOOGLE_MAP_STREETVIEW_LATLNG = "cbll";
  static const AUTH_TOKEN = "Bearer 4htbz9nLozJ_-Xw-13LpeVWrEIRWZt4IrgTOQXstx7M1DCVeUIoxIZkQ0XVLVEtD2Gy2Vp1FjA2WRz5DOpZMSxHfXVBLR3gi0DeMXIV3X1bCHYoMoJ-_TZLfBn0ZWnYx";
  static const LOCALE = "zh_TW";
  static const int CONNECTION_TIEMOUT = 30000;
  static const int RECEIVE_TIEMOUT = 30000;
  static const int PAGE_ITEM_COUNT = 50;

}