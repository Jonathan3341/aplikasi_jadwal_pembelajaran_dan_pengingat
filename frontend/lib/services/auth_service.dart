import 'package:dio/dio.dart';

import 'api_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final ApiService _api = ApiService.instance;

  Future<bool> validateSession() async {
    await _api.init();

    final hasToken = await _api.hasAccessToken();

    // 1. Jika access token tersedia, periksa validitasnya.
    if (hasToken) {
      try {
        await _api.dio.get('/api/user/profile');
        return true;
      } on DioException catch (e) {
        // Hanya lakukan refresh jika access token ditolak
        // karena tidak valid atau sudah kedaluwarsa.
        if (e.response?.statusCode != 401) {
          return false;
        }
      }
    }

    // 2. Jika access token tidak tersedia atau kedaluwarsa,
    // coba mendapatkan access token baru melalui refresh cookie.
    final refreshed = await refreshToken();

    if (!refreshed) {
      return false;
    }

    // 3. Periksa kembali profil menggunakan access token baru.
    try {
      await _api.dio.get('/api/user/profile');
      return true;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;

      if (statusCode == 401 || statusCode == 403) {
        await _api.clearAccessToken();
      }

      return false;
    }
  }

  // ==========================================
  // REGISTER
  // ==========================================

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String nim,
    required String major,
  }) async {
    await _api.init();

    try {
      await _api.dio.post(
        '/api/user/register',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'nim': nim.trim(),
          'major': major.trim(),
        },
      );
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ==========================================
  // LOGIN
  // ==========================================

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await _api.init();

    try {
      final response = await _api.dio.post(
        '/api/user/login',
        data: {'email': email.trim(), 'password': password},
      );

      final data = Map<String, dynamic>.from(response.data);

      final token = data['accessToken'];

      if (token == null || token.toString().isEmpty) {
        throw Exception('Access token tidak ditemukan.');
      }

      await _api.saveAccessToken(token.toString());

      return data;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ==========================================
  // REFRESH TOKEN
  // ==========================================

  Future<bool> refreshToken() async {
    await _api.init();

    try {
      final response = await _api.dio.post('/api/user/refresh');

      final data = Map<String, dynamic>.from(response.data);
      final token = data['accessToken'];

      if (token == null || token.toString().isEmpty) {
        return false;
      }

      await _api.saveAccessToken(token.toString());

      return true;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;

      // Hapus access token jika refresh token ditolak.
      if (statusCode == 401 || statusCode == 403) {
        await _api.clearAccessToken();
      }

      return false;
    }
  }

  // ==========================================
  // PROFILE
  // ==========================================

  Future<Map<String, dynamic>> getProfile() async {
    await _api.init();

    try {
      final response = await _api.dio.get('/api/user/profile');

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ==========================================
  // LOGOUT
  // ==========================================

  Future<void> logout() async {
    await _api.init();

    try {
      await _api.dio.post('/api/user/logout');
    } finally {
      await _api.clearAccessToken();
    }
  }

  // ==========================================
  // ERROR MESSAGE
  // ==========================================

  String _getErrorMessage(DioException e) {
    final responseData = e.response?.data;

    if (responseData is Map) {
      final message = responseData['message'];

      if (message != null) {
        return message.toString();
      }
    }

    if (e.response?.statusCode == 401) {
      return 'Email, password, atau sesi tidak valid.';
    }

    if (e.response?.statusCode == 403) {
      return 'Kamu tidak memiliki izin untuk mengakses fitur ini.';
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Koneksi ke server mengalami timeout.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server.';
    }

    return 'Terjadi kesalahan: ${e.message}';
  }
}
