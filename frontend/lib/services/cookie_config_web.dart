import 'package:dio/dio.dart';
import 'package:dio/browser.dart';

Future<void> configureCookies(Dio dio) async {
  dio.httpClientAdapter = BrowserHttpClientAdapter()..withCredentials = true;
}
