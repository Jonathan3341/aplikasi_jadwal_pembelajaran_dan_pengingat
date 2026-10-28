
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_task.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  Future<List<ApiTask>> fetchTasks() async {
    final uri = Uri.parse(
      'https://jsonplaceholder.typicode.com/todos?_limit=20',
    );

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Server mengembalikan status ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw const FormatException(
        'Format respons API tidak sesuai.',
      );
    }

    return decoded.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException(
          'Data tugas dari API tidak valid.',
        );
      }

      return ApiTask.fromJson(item);
    }).toList();
  }
}
