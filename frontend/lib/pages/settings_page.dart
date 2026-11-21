import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/native_intent_service.dart';
import '../services/preferences_service.dart';
import '../services/quote_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _orange = Color(0xFFFF7A00);
  static const _dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  final _prefs = PreferencesService.instance;

  bool _loading = true;
  int _reminderLead = 30;
  bool _notifSound = true;
  String _view = 'harian';
  final Set<String> _studyDays = {};

  bool _quoteLoading = false;
  String? _quote;
  String? _quoteAuthor;
  String? _quoteError;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadQuote();
  }

  Future<void> _loadPrefs() async {
    final lead = await _prefs.getReminderLead();
    final sound = await _prefs.getNotifSound();
    final view = await _prefs.getScheduleView();
    final days = await _prefs.getStudyDays();

    if (!mounted) return;

    setState(() {
      _reminderLead = lead;
      _notifSound = sound;
      _view = view;
      _studyDays
        ..clear()
        ..addAll(days);
      _loading = false;
    });
  }

  Future<void> _loadQuote() async {
    setState(() {
      _quoteLoading = true;
      _quoteError = null;
    });

    try {
      final result = await QuoteService.instance.fetchRandomQuote();

      if (!mounted) return;

      setState(() {
        _quote = result.quote;
        _quoteAuthor = result.author;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _quoteError = 'Gagal memuat kutipan. Cek koneksi internet.');
    } finally {
      if (mounted) setState(() => _quoteLoading = false);
    }
  }

  Future<void> _openNotificationSettings() async {
    final opened = await NativeIntentService.openNotificationSettings();

    if (!mounted || opened) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur ini hanya tersedia di perangkat Android.'),
      ),
    );
  }

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@example.com',
      queryParameters: {'subject': 'Masukan Aplikasi Jadwal Pembelajaran'},
    );

    try {
      final launched = await launchUrl(uri);
      if (launched || !mounted) return;
    } catch (_) {}

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak ada aplikasi email di perangkat.')),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ---------- RADIO ----------
                _section('Waktu Pengingat Bawaan'),
                Card(
                  color: Colors.white,
                  child: RadioGroup<int>(
                    groupValue: _reminderLead,
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() => _reminderLead = value);
                      await _prefs.setReminderLead(value);
                    },
                    child: const Column(
                      children: [
                        RadioListTile<int>(
                          value: 10,
                          title: Text('10 menit sebelum kelas'),
                        ),
                        RadioListTile<int>(
                          value: 30,
                          title: Text('30 menit sebelum kelas'),
                        ),
                        RadioListTile<int>(
                          value: 60,
                          title: Text('1 jam sebelum kelas'),
                        ),
                      ],
                    ),
                  ),
                ),

                // ---------- SWITCH ----------
                _section('Notifikasi'),
                Card(
                  color: Colors.white,
                  child: SwitchListTile(
                    value: _notifSound,
                    activeThumbColor: _orange,
                    title: const Text('Suara notifikasi'),
                    subtitle: const Text('Bunyikan suara saat pengingat muncul'),
                    onChanged: (value) async {
                      setState(() => _notifSound = value);
                      await _prefs.setNotifSound(value);
                    },
                  ),
                ),

                // ---------- TOGGLE BUTTONS ----------
                _section('Tampilan Jadwal Favorit'),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ToggleButtons(
                    isSelected: [_view == 'harian', _view == 'bulanan'],
                    borderRadius: BorderRadius.circular(10),
                    selectedColor: Colors.white,
                    fillColor: _orange,
                    onPressed: (index) async {
                      final value = index == 0 ? 'harian' : 'bulanan';
                      setState(() => _view = value);
                      await _prefs.setScheduleView(value);
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text('Harian'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text('Bulanan'),
                      ),
                    ],
                  ),
                ),

                // ---------- CHECKBOX ----------
                _section('Hari Belajar Mandiri'),
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Wrap(
                      children: _dayNames.map((day) {
                        return SizedBox(
                          width: 110,
                          child: CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: _orange,
                            title: Text(day),
                            value: _studyDays.contains(day),
                            onChanged: (checked) async {
                              setState(() {
                                if (checked == true) {
                                  _studyDays.add(day);
                                } else {
                                  _studyDays.remove(day);
                                }
                              });
                              await _prefs.setStudyDays(_studyDays.toList());
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // ---------- INTENTS ----------
                _section('Bantuan'),
                Card(
                  color: Colors.white,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notifications_active_outlined),
                        title: const Text('Buka pengaturan notifikasi sistem'),
                        trailing: const Icon(Icons.open_in_new, size: 18),
                        onTap: _openNotificationSettings,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.mail_outline),
                        title: const Text('Kirim masukan lewat email'),
                        trailing: const Icon(Icons.open_in_new, size: 18),
                        onTap: _contactSupport,
                      ),
                    ],
                  ),
                ),

                // ---------- API ----------
                _section('Motivasi Belajar'),
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_quoteLoading)
                          const Center(
                            child: CircularProgressIndicator(color: _orange),
                          )
                        else if (_quoteError != null)
                          Text(
                            _quoteError!,
                            style: const TextStyle(color: Colors.red),
                          )
                        else ...[
                          Text(
                            '"${_quote ?? '-'}"',
                            style: const TextStyle(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '— ${_quoteAuthor ?? '-'}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _quoteLoading ? null : _loadQuote,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Kutipan baru'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
