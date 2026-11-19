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
      return 'http://192.168.1.10:5000';
    }

    return 'http://localhost:5000';
  }


  //guru update tugas
  Future<Map<String, dynamic>> updateAssignment({
    required int id,
    required String title,
    required String description,
  }) async {
    final response = await dio.put(
      '/api/assignments/$id',
      data: {
        'title': title,
        'description': description,
      },
    );

    return Map<String, dynamic>.from(
      response.data['data'],
    );
  }

  //admin menghapus guru
  Future<void> deleteTeacher(int id) async {
    await dio.delete('/api/admin/teachers/$id');
  }

  // Mengambil daftar murid dari kelas yang ditugaskan kepada Guru.
  Future<List<Map<String, dynamic>>> fetchClassStudents(int classId) async {
    final response = await dio.get(
      '/api/schedules/classes/$classId/students',
    );

    final responseData = response.data as Map<String, dynamic>;
    final students = responseData['data'] as List;

    return students
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
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



// ADMIN - TEACHERS

// Mengambil daftar akun Guru dari backend.
  Future<List<Map<String, dynamic>>> fetchTeachers() async {
    final response = await dio.get('/api/admin/teachers');

    final data = response.data['data'] as List;

    return data
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // Membuat akun Guru baru.
  Future<Map<String, dynamic>> createTeacher({
    required String name,
    required String email,
    required String password,
    required String major,
  }) async {
    final response = await dio.post(
      '/api/admin/teachers',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'major': major,
      },
    );

    return Map<String, dynamic>.from(response.data['data']);
  }

  // Mengambil daftar kelas yang tersedia untuk registrasi Murid.
  // Endpoint ini bersifat publik sehingga dapat dipanggil
  // sebelum pengguna melakukan login.
  Future<List<Map<String, dynamic>>> fetchRegistrationClasses() async {
    final response = await dio.get(
      '/api/user/registration-classes',
    );

    final data = response.data['data'] as List;

    return data
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
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

  // Mengambil daftar Murid dari backend.
  Future<List<Map<String, dynamic>>> fetchStudents({
    int? classId,
    String? search,
  }) async {
    final queryParameters = <String, dynamic>{};

    if (classId != null) {
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

    return data
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }


  // ==========================================
  // ASSIGNMENTS - TUGAS GURU DAN MURID
  // ==========================================

  // Mengambil daftar tugas sesuai role pengguna.
  Future<List<Map<String, dynamic>>> fetchAssignments() async {
    final response = await dio.get('/api/assignments');

    final data = response.data['data'] as List;

    return data
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // Mengambil detail tugas.
  Future<Map<String, dynamic>> fetchAssignmentDetail(int id) async {
    final response = await dio.get('/api/assignments/$id');

    return Map<String, dynamic>.from(response.data['data']);
  }

  // Membuat tugas baru beserta lampiran.
  Future<Map<String, dynamic>> createAssignment({
    required int classId,
    required String title,
    required String description,
    String? dueAt,
    List<MultipartFile> files = const [],
    List<Map<String, dynamic>> links = const [],
  }) async {
    final formData = FormData();

    formData.fields.add(MapEntry('class_id', classId.toString()));
    formData.fields.add(MapEntry('title', title));
    formData.fields.add(MapEntry('description', description));

    if (dueAt != null && dueAt.isNotEmpty) {
      formData.fields.add(MapEntry('due_at', dueAt));
    }

    formData.fields.add(MapEntry('links', jsonEncode(links)));

    for (final file in files) {
      formData.files.add(MapEntry('attachments', file));
    }

    final response = await dio.post(
      '/api/assignments',
      data: formData,
    );

    return Map<String, dynamic>.from(response.data['data']);
  }

  // ==========================================
  // SUBMISSIONS - PENGUMPULAN TUGAS
  // ==========================================

  // Murid mengumpulkan jawaban tugas.
  Future<Map<String, dynamic>> submitAssignment({
    required int assignmentId,
    List<MultipartFile> files = const [],
    List<Map<String, dynamic>> links = const [],
  }) async {
    final formData = FormData();

    formData.fields.add(
      MapEntry('links', jsonEncode(links)),
    );

    for (final file in files) {
      formData.files.add(MapEntry('attachments', file));
    }

    final response = await dio.post(
      '/api/submissions/$assignmentId',
      data: formData,
    );

    return Map<String, dynamic>.from(response.data['data']);
  }

  // Guru melihat pengumpulan untuk tugas miliknya.
  Future<List<Map<String, dynamic>>> fetchAssignmentSubmissions(
      int assignmentId,
      ) async {
    final response = await dio.get(
      '/api/submissions/assignment/$assignmentId',
    );

    final data = response.data['data'] as List;

    return data
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // Murid melihat riwayat pengumpulan tugas.
  Future<List<Map<String, dynamic>>> fetchMySubmissions() async {
    final response = await dio.get(
      '/api/submissions/my-submissions',
    );

    final data = response.data['data'] as List;

    return data
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // Guru memberikan nilai dan feedback.
  Future<Map<String, dynamic>> gradeSubmission({
    required int submissionId,
    required double grade,
    String feedback = '',
  }) async {
    final response = await dio.put(
      '/api/submissions/$submissionId/grade',
      data: {
        'grade': grade,
        'feedback': feedback,
      },
    );

    return Map<String, dynamic>.from(response.data['data']);
  }

  // ==========================================
  // DOWNLOAD LAMPIRAN
  // ==========================================

  // Mengunduh lampiran tugas dari Guru.
  Future<List<int>> downloadAssignmentAttachment(int attachmentId) async {
    final response = await dio.get<List<int>>(
      '/api/assignments/attachments/$attachmentId/download',
      options: Options(responseType: ResponseType.bytes),
    );

    return response.data ?? [];
  }

  // Mengunduh jawaban Murid.
  Future<List<int>> downloadSubmissionAttachment(int attachmentId) async {
    final response = await dio.get<List<int>>(
      '/api/submissions/attachments/$attachmentId/download',
      options: Options(responseType: ResponseType.bytes),
    );

    return response.data ?? [];
  }


  // ==========================================
  // ATTENDANCE - ABSENSI MURID
  // ==========================================

  // Mengambil jadwal dan status absensi hari ini.
  Future<Map<String, dynamic>> fetchAvailableAttendance() async {
    final response = await dio.get('/api/attendance/available');

    return Map<String, dynamic>.from(response.data);
  }

  // Mengirim absensi berdasarkan lokasi GPS.
  Future<Map<String, dynamic>> submitAttendance({
    required int scheduleId,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    final response = await dio.post(
      '/api/attendance',
      data: {
        'schedule_id': scheduleId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }

  // Mengambil riwayat absensi Murid.
  Future<List<Map<String, dynamic>>> fetchMyAttendance() async {
    final response = await dio.get('/api/attendance/my-history');

    final data = response.data['attendance'] as List;

    return data
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

// Mengambil rekap keseluruhan absensi Murid.
  Future<Map<String, dynamic>> fetchMyAttendanceSummary() async {
    final response = await dio.get('/api/attendance/summary');

    final data = response.data['data'];

    if (data is! Map) {
      throw const FormatException(
        'Format rekap kehadiran dari server tidak sesuai.',
      );
    }

    return Map<String, dynamic>.from(data);
  }
}
