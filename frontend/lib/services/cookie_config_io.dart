import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

Future<void> configureCookies(Dio dio) async {
  final directory = await getApplicationDocumentsDirectory();

  final cookieJar = PersistCookieJar(
    storage: FileStorage('${directory.path}/.cookies/'),
  );

  dio.interceptors.add(CookieManager(cookieJar));
}
