
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class AssignmentFileHelper {
  static const int maxFiles = 5;
  static const int maxFileSize = 10 * 1024 * 1024;

  static const List<String> allowedExtensions = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  // Memilih beberapa file sekaligus.
  static Future<List<PlatformFile>> pickFiles({
    List<PlatformFile> existingFiles = const [],
  }) async {
    final remainingSlots = maxFiles - existingFiles.length;

    if (remainingSlots <= 0) {
      throw Exception('Maksimal 5 file lampiran.');
    }

    final selectedFiles = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (selectedFiles.isEmpty) {
      return [];
    }

    if (selectedFiles.length > remainingSlots) {
      throw Exception(
        'Kamu hanya dapat menambahkan $remainingSlots file lagi.',
      );
    }

    for (final file in selectedFiles) {
      final size = file.lengthSync() ?? await file.length();

      if (size == null) {
        throw Exception('Ukuran file ${file.name} tidak dapat dibaca.');
      }

      if (size > maxFileSize) {
        throw Exception(
          'File ${file.name} melebihi batas 10 MB.',
        );
      }
    }

    return selectedFiles;
  }

  // Mengubah file menjadi MultipartFile untuk Dio.
  static Future<List<MultipartFile>> toMultipartFiles(
      List<PlatformFile> files,
      ) async {
    final result = <MultipartFile>[];

    for (final file in files) {
      final bytes = await file.readAsBytes();

      result.add(
        MultipartFile.fromBytes(
          bytes,
          filename: file.name,
        ),
      );
    }

    return result;
  }
}
