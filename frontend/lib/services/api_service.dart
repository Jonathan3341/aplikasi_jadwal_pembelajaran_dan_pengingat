import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/api_task.dart';

import 'cookie_config_io.dart' if (dart.library.html) 'cookie_config_web.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  late final Dio dio;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _initialized = false;

  // Alamat backend Node.js
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }

    return 'http://localhost:5000';
  }

  // Mengambil seluruh jadwal dari backend.
  Future<List<Map<String, dynamic>>> fetchSchedules() async {
    final response = await dio.get('/api/schedules');

    final responseData = response.data as Map<String, dynamic>;
    final schedules = responseData['data'] as List;

    return schedules.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  // Menambahkan jadwal baru.
  Future<Map<String, dynamic>> createSchedule(
    Map<String, dynamic> schedule,
  ) async {
    final response = await dio.post('/api/schedules', data: schedule);

    return Map<String, dynamic>.from(response.data['data']);
  }

  // Memperbarui jadwal berdasarkan ID.
  Future<Map<String, dynamic>> updateSchedule(
    String id,
    Map<String, dynamic> schedule,
  ) async {
    final response = await dio.put('/api/schedules/$id', data: schedule);

    return Map<String, dynamic>.from(response.data['data']);
  }

  // Menghapus jadwal berdasarkan ID.
  Future<void> deleteSchedule(String id) async {
    await dio.delete('/api/schedules/$id');
  }

  // Inisialisasi Dio dan cookie
  Future<void> init() async {
    if (_initialized) return;

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Konfigurasi cookie sesuai platform
    await configureCookies(dio);

    // Menambahkan access token ke request
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getAccessToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
      ),
    );

    _initialized = true;
  }

  // ==========================================
  // ACCESS TOKEN
  // ==========================================

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: 'accessToken', value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'accessToken');
  }

  Future<void> clearAccessToken() async {
    await _storage.delete(key: 'accessToken');
  }

  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();

    return token != null && token.isNotEmpty;
  }

  // ==========================================
  // REST API GET - JSONPLACEHOLDER
  // Tetap dipertahankan untuk tugas kuliah
  // ==========================================

  Future<List<ApiTask>> fetchTasks() async {
    final uri = Uri.parse(
      'https://jsonplaceholder.typicode.com/todos?_limit=20',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Server mengembalikan status ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw const FormatException('Format respons API tidak sesuai.');
    }

    return decoded.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Data tugas dari API tidak valid.');
      }

      return ApiTask.fromJson(item);
    }).toList();
  }

  // ==========================================
  // ADMIN - ACADEMIC CLASSES
  // ==========================================

  Future<List<Map<String, dynamic>>> fetchClasses() async {
    final response = await dio.get('/api/admin/classes');

    final data = response.data['data'] as List;

    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<Map<String, dynamic>> createClass(Map<String, dynamic> data) async {
    final response = await dio.post('/api/admin/classes', data: data);

    return Map<String, dynamic>.from(response.data['data']);
  }

  Future<Map<String, dynamic>> updateClass(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.put('/api/admin/classes/$id', data: data);

    return Map<String, dynamic>.from(response.data['data']);
  }

  Future<void> deleteClass(int id) async {
    await dio.delete('/api/admin/classes/$id');
  }

  // ==========================================
  // ADMIN - STUDENTS
  // ==========================================

  Future<List<Map<String, dynamic>>> fetchStudents({
    int? classId,
    bool unassigned = false,
    String? search,
  }) async {
    final queryParameters = <String, dynamic>{};

    if (unassigned) {
      queryParameters['class_id'] = 'unassigned';
    } else if (classId != null) {
      queryParameters['class_id'] = classId;
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    final response = await dio.get(
      '/api/admin/students',
      queryParameters: queryParameters,
    );

    final data = response.data['data'] as List;

    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<Map<String, dynamic>> assignStudentToClass({
    required String nim,
    required int? classId,
  }) async {
    final response = await dio.put(
      '/api/admin/students/class',
      data: {'nim': nim, 'class_id': classId},
    );

    return Map<String, dynamic>.from(response.data['data']);
  }
}
