import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import '../services/location_service.dart';

class AttendanceMapPage extends StatefulWidget {
  const AttendanceMapPage({super.key});

  @override
  State<AttendanceMapPage> createState() => _AttendanceMapPageState();
}

class _AttendanceMapPageState extends State<AttendanceMapPage> {
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService.instance;
  final MapController _mapController = MapController();

  static const LatLng _campusLocation = LatLng(
    LocationService.campusLatitude,
    LocationService.campusLongitude,
  );

  // Lokasi GPS pengguna.
  Position? _currentPosition;
  double? _distance;

  bool _isLoading = false;
  String? _errorMessage;

  // Data jadwal dan riwayat absensi.
  List<Map<String, dynamic>> _todaySchedules = [];
  List<Map<String, dynamic>> _attendanceHistory = [];

  int? _selectedScheduleId;
  String? _attendanceDate;

  // Status loading API.
  bool _isLoadingSchedules = true;
  bool _isLoadingHistory = true;
  bool _isSubmittingAttendance = false;

  String? _scheduleError;
  String? _historyError;

  String? _attendanceActionMessage;
  bool? _attendanceActionSuccess;

  // Memeriksa jarak lokasi pengguna ke kampus.
  bool get _isWithinRadius {
    return _currentPosition != null &&
        _locationService.isWithinAttendanceRadius(_currentPosition!);
  }

  // Akurasi GPS maksimal 50 meter.
  bool get _isGpsAccurate {
    return _currentPosition != null && _currentPosition!.accuracy <= 50;
  }

  // Mengambil jadwal yang sedang dipilih.
  Map<String, dynamic>? get _selectedSchedule {
    if (_selectedScheduleId == null) return null;

    for (final schedule in _todaySchedules) {
      if (int.tryParse(schedule['id'].toString()) == _selectedScheduleId) {
        return schedule;
      }
    }

    return null;
  }

  // Memeriksa apakah semua syarat absensi terpenuhi.
  bool get _canSubmitAttendance {
    return _selectedSchedule != null &&
        _selectedSchedule!['can_attend'] == true &&
        _currentPosition != null &&
        _isWithinRadius &&
        _isGpsAccurate &&
        !_isSubmittingAttendance &&
        !_isLoading;
  }

  @override
  void initState() {
    super.initState();

    _getCurrentLocation();
    _loadAvailableAttendance();
    _loadAttendanceHistory();
  }

  // Memindahkan peta ke lokasi kampus.
  void _moveToCampus() {
    _mapController.move(_campusLocation, 17);
  }

  // Memindahkan peta ke lokasi pengguna.
  void _moveToMyLocation() {
    if (_currentPosition == null) return;

    _mapController.move(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      18,
    );
  }

  // API MENGAMBIL JADWAL ABSENSI

  Future<void> _loadAvailableAttendance() async {
    if (!mounted) return;

    setState(() {
      _isLoadingSchedules = true;
      _scheduleError = null;
    });

    try {
      final response = await _apiService.fetchAvailableAttendance();

      final rawSchedules = response['schedules'] as List? ?? [];

      final schedules = rawSchedules
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (!mounted) return;

      setState(() {
        _todaySchedules = schedules;
        _attendanceDate = response['date']?.toString();

        final selectionExists = schedules.any(
          (schedule) =>
              int.tryParse(schedule['id'].toString()) == _selectedScheduleId,
        );

        if (!selectionExists) {
          _selectedScheduleId = schedules.isNotEmpty
              ? int.tryParse(schedules.first['id'].toString())
              : null;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _scheduleError = _getErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSchedules = false;
        });
      }
    }
  }

  // API MENGAMBIL RIWAYAT ABSENSI

  Future<void> _loadAttendanceHistory() async {
    if (!mounted) return;

    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    try {
      final history = await _apiService.fetchMyAttendance();

      if (!mounted) return;

      setState(() {
        _attendanceHistory = history;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _historyError = _getErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  // MENANGANI PESAN ERROR API

  String _getErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Tidak dapat menghubungi server. '
            'Periksa koneksi dan server backend.';
      }

      return error.message ?? 'Terjadi kesalahan saat menghubungi server.';
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  // API MENGIRIM ABSENSI

  Future<void> _submitAttendance() async {
    if (!_canSubmitAttendance) return;

    final schedule = _selectedSchedule!;
    final position = _currentPosition!;

    final scheduleId = int.tryParse(schedule['id'].toString());

    if (scheduleId == null) return;

    setState(() {
      _isSubmittingAttendance = true;
      _attendanceActionMessage = null;
      _attendanceActionSuccess = null;
    });

    try {
      final response = await _apiService.submitAttendance(
        scheduleId: scheduleId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );

      final attendance = response['attendance'];

      final status = attendance is Map
          ? attendance['status']?.toString()
          : null;

      if (!mounted) return;

      setState(() {
        _attendanceActionSuccess = true;

        _attendanceActionMessage =
            '${response['message'] ?? 'Absensi berhasil.'}'
            '${status == null ? '' : ' Status: $status.'}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_attendanceActionMessage!),
          backgroundColor: Colors.green,
        ),
      );

      // Memperbarui data dari backend setelah berhasil.
      await _loadAvailableAttendance();
      await _loadAttendanceHistory();
    } catch (e) {
      if (!mounted) return;

      final message = _getErrorMessage(e);

      setState(() {
        _attendanceActionSuccess = false;
        _attendanceActionMessage = message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingAttendance = false;
        });
      }
    }
  }

  // GPS: MENGAMBIL LOKASI PENGGUNA

  Future<void> _getCurrentLocation() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;

      // Hapus lokasi lama agar tidak digunakan untuk absensi.
      _currentPosition = null;
      _distance = null;
    });

    try {
      final position = await _locationService.getCurrentPosition();

      if (!mounted) return;

      final distance = _locationService.calculateDistance(position);

      setState(() {
        _currentPosition = position;
        _distance = distance;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // TAMPILAN UTAMA

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absensi Lokasi'), centerTitle: true),

      body: Column(
        children: [
          // PETA OPENSTREETMAP.
          Expanded(
            flex: 5,
            child: FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: _campusLocation,
                initialZoom: 17,
                minZoom: 5,
                maxZoom: 19,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.example.aplikasi_jadwal_pembelajaran_dan_pengingat',
                ),

                // Lingkaran radius absensi 100 meter.
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _campusLocation,
                      radius: LocationService.attendanceRadius,
                      useRadiusInMeter: true,
                      color: Colors.blue.withValues(alpha: 0.15),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),

                // Penanda kampus dan lokasi pengguna.
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _campusLocation,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 42,
                      ),
                    ),

                    if (_currentPosition != null)
                      Marker(
                        point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        width: 45,
                        height: 45,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 28,
                          ),
                        ),
                      ),
                  ],
                ),

                // Atribusi OpenStreetMap.
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),

          // INFORMASI GPS, JADWAL, DAN RIWAYAT.
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Tombol navigasi peta.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _moveToCampus,
                            icon: const Icon(Icons.school_outlined),
                            label: const Text('Lokasi Kampus'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _currentPosition == null
                                ? null
                                : _moveToMyLocation,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Lokasi Saya'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildLocationInformation(),

                  _buildAttendanceSection(),

                  _buildAttendanceHistorySection(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // INFORMASI LOKASI DAN GPS

  Widget _buildLocationInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Universitas Tarumanagara Kampus 1',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          const Text(
            'Radius absensi: 100 meter',
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 16),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            _buildErrorInformation()
          else if (_currentPosition != null)
            _buildSuccessInformation()
          else
            const Text('Lokasi belum tersedia.'),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _getCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Perbarui Lokasi'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorInformation() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _isWithinRadius ? Icons.check_circle : Icons.location_off,
              color: _isWithinRadius ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isWithinRadius
                    ? 'Kamu berada dalam radius kampus.'
                    : 'Kamu berada di luar radius kampus.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _isWithinRadius ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Text(
          'Jarak dari kampus: '
          '${_distance!.toStringAsFixed(1)} meter',
        ),

        const SizedBox(height: 4),

        Text(
          'Akurasi GPS: '
          '${_currentPosition!.accuracy.toStringAsFixed(1)} meter',
          style: const TextStyle(color: Colors.grey),
        ),

        if (!_isGpsAccurate) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Akurasi GPS rendah. Perbarui lokasi atau '
                  'coba di area terbuka.',
                  style: TextStyle(color: Colors.orange, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // STATUS JADWAL DAN ABSENSI

  Color _attendanceStateColor(String state) {
    switch (state) {
      case 'Dibuka':
        return Colors.green;
      case 'Sudah Absen':
        return Colors.blue;
      case 'Ditutup':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // Menjelaskan alasan tombol absensi belum aktif.
  String? _attendanceDisabledReason() {
    if (_isLoadingSchedules) {
      return 'Sedang mengambil jadwal absensi...';
    }

    final schedule = _selectedSchedule;

    if (schedule == null) {
      return 'Tidak ada jadwal yang dapat dipilih.';
    }

    final state = schedule['attendance_state']?.toString();

    if (state == 'Sudah Absen') {
      return 'Kamu sudah melakukan absensi untuk jadwal ini.';
    }

    if (state != 'Dibuka' || schedule['can_attend'] != true) {
      if (state == 'Belum Dibuka') {
        return 'Absensi belum dibuka.';
      }

      if (state == 'Ditutup') {
        return 'Waktu absensi sudah ditutup.';
      }

      return 'Absensi belum tersedia untuk jadwal ini.';
    }

    if (_isLoading) {
      return 'Sedang memperbarui lokasi GPS...';
    }

    if (_currentPosition == null) {
      return 'Aktifkan GPS dan perbarui lokasi terlebih dahulu.';
    }

    if (!_isGpsAccurate) {
      return 'Akurasi GPS harus maksimal 50 meter.';
    }

    if (!_isWithinRadius) {
      return 'Kamu harus berada dalam radius 100 meter dari kampus.';
    }

    if (_isSubmittingAttendance) {
      return 'Sedang mengirim absensi...';
    }

    return null;
  }

  // TAMPILAN JADWAL ABSENSI

  Widget _buildAttendanceSection() {
    final schedule = _selectedSchedule;

    final state = schedule?['attendance_state']?.toString() ?? '';

    final stateColor = _attendanceStateColor(state);

    final disabledReason = _attendanceDisabledReason();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Jadwal Absensi Hari Ini',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Perbarui jadwal',
                onPressed: _isLoadingSchedules
                    ? null
                    : _loadAvailableAttendance,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),

          if (_attendanceDate != null) ...[
            Text(
              'Tanggal: $_attendanceDate (WIB)',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],

          const SizedBox(height: 14),

          if (_isLoadingSchedules)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_scheduleError != null)
            Text(_scheduleError!, style: const TextStyle(color: Colors.red))
          else if (_todaySchedules.isEmpty)
            const Text(
              'Tidak ada jadwal perkuliahan hari ini.',
              style: TextStyle(color: Colors.grey),
            )
          else ...[
            // Dropdown pilihan mata kuliah.
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Pilih mata kuliah',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedScheduleId,
                  isExpanded: true,
                  items: _todaySchedules
                      .map((item) {
                        final id = int.tryParse(item['id'].toString());

                        if (id == null) return null;

                        final subject =
                            item['subject']?.toString() ?? 'Mata kuliah';

                        final start = item['start_time']?.toString() ?? '';

                        final end = item['end_time']?.toString() ?? '';

                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(
                            '$subject ($start - $end)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      })
                      .whereType<DropdownMenuItem<int>>()
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedScheduleId = value;
                      _attendanceActionMessage = null;
                      _attendanceActionSuccess = null;
                    });
                  },
                ),
              ),
            ),

            if (schedule != null) ...[
              const SizedBox(height: 14),

              // Label status absensi.
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: stateColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      state,
                      style: TextStyle(
                        color: stateColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text('Mata kuliah: ${schedule['subject'] ?? '-'}'),

              Text(
                'Waktu kuliah: '
                '${schedule['start_time'] ?? '-'} - '
                '${schedule['end_time'] ?? '-'}',
              ),

              Text('Ruangan: ${schedule['room'] ?? '-'}'),

              const SizedBox(height: 8),

              Text(
                'Waktu absensi: '
                '${schedule['window_opens_at'] ?? '-'} - '
                '${schedule['window_closes_at'] ?? '-'} WIB',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),

              if (schedule['attendance_status'] != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Status kehadiran: '
                  '${schedule['attendance_status']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Tombol mengirim absensi.
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _canSubmitAttendance ? _submitAttendance : null,
                  icon: _isSubmittingAttendance
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.how_to_reg),
                  label: Text(
                    _isSubmittingAttendance
                        ? 'Mengirim Absensi...'
                        : 'Absen Sekarang',
                  ),
                ),
              ),

              if (disabledReason != null) ...[
                const SizedBox(height: 8),
                Text(
                  disabledReason,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ],
          ],

          // Pesan hasil pengiriman absensi.
          if (_attendanceActionMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    (_attendanceActionSuccess == true
                            ? Colors.green
                            : Colors.red)
                        .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _attendanceActionMessage!,
                style: TextStyle(
                  color: _attendanceActionSuccess == true
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // FORMAT WAKTU ABSENSI

  String _formatCheckInTime(String? value) {
    if (value == null || value.isEmpty) return '-';

    final dateTime = DateTime.tryParse(value);

    if (dateTime == null) return value;

    // Konversi ke WIB (UTC+7).
    final jakartaTime = dateTime.toUtc().add(const Duration(hours: 7));

    final hour = jakartaTime.hour.toString().padLeft(2, '0');
    final minute = jakartaTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  // TAMPILAN RIWAYAT ABSENSI

  Widget _buildAttendanceHistorySection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Riwayat Absensi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Perbarui riwayat',
                onPressed: _isLoadingHistory ? null : _loadAttendanceHistory,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),

          if (_isLoadingHistory)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_historyError != null)
            Text(_historyError!, style: const TextStyle(color: Colors.red))
          else if (_attendanceHistory.isEmpty)
            const Text(
              'Belum ada riwayat absensi.',
              style: TextStyle(color: Colors.grey),
            )
          else
            ..._attendanceHistory.take(5).map((item) {
              final status = item['status']?.toString() ?? '-';

              final statusColor = status == 'Hadir'
                  ? Colors.green
                  : Colors.orange;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.event_available)),
                title: Text(
                  item['subject']?.toString() ?? 'Mata kuliah',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${item['attendance_date'] ?? '-'}'
                  ' • ${_formatCheckInTime(item['check_in_at']?.toString())}',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
