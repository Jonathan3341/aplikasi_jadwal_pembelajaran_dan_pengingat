
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Koordinat awal Universitas Tarumanagara Kampus 1.
  static const double campusLatitude = -6.1690517 ;
  static const double campusLongitude = 106.7903548 ;

  // Radius absensi dalam meter.
  static const double attendanceRadius = 100;

  /// Memeriksa GPS dan meminta izin lokasi jika diperlukan.
  Future<bool> checkLocationPermission() async {
    final serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'GPS belum aktif. Silakan aktifkan layanan lokasi.',
      );
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'Izin lokasi ditolak. Izinkan aplikasi mengakses lokasi.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi ditolak permanen. Aktifkan izin melalui pengaturan perangkat atau browser.',
      );
    }

    return true;
  }

  /// Mengambil posisi GPS mahasiswa saat ini.
  Future<Position> getCurrentPosition() async {
    await checkLocationPermission();

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (e) {
      throw Exception(
        'Gagal mendapatkan lokasi GPS: $e',
      );
    }
  }

  /// Menghitung jarak mahasiswa ke titik kampus dalam meter.
  double calculateDistance(Position position) {
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      campusLatitude,
      campusLongitude,
    );
  }

  /// Memeriksa apakah mahasiswa berada dalam radius absensi.
  bool isWithinAttendanceRadius(Position position) {
    final distance = calculateDistance(position);

    return distance <= attendanceRadius;
  }

  /// Membuka pengaturan lokasi perangkat.
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Membuka pengaturan izin aplikasi.
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}
