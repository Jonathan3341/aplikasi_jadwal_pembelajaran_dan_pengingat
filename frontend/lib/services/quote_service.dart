import 'package:dio/dio.dart';

/// Mengambil kutipan motivasi dari API publik (di luar backend Node.js).
class QuoteService {
  QuoteService._();

  static final QuoteService instance = QuoteService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  Future<({String quote, String author})> fetchRandomQuote() async {
    final response = await _dio.get('https://dummyjson.com/quotes/random');
    final data = Map<String, dynamic>.from(response.data as Map);

    return (
      quote: data['quote']?.toString() ?? '',
      author: data['author']?.toString() ?? '',
    );
  }
}
