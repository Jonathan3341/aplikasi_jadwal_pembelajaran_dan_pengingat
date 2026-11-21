import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan preferensi lokal (Data Persistence) memakai SharedPreferences.
/// Tidak menyentuh AppData / alur jadwal yang sudah ada.
class PreferencesService {
  PreferencesService._();

  static final PreferencesService instance = PreferencesService._();

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static const _kRemember = 'pref_remember_email';
  static const _kEmail = 'pref_saved_email';
  static const _kLead = 'pref_reminder_lead';
  static const _kSound = 'pref_notif_sound';
  static const _kView = 'pref_schedule_view';
  static const _kDays = 'pref_study_days';

  // Login: ingat email
  Future<bool> getRememberEmail() async =>
      await _prefs.getBool(_kRemember) ?? false;

  Future<void> setRememberEmail(bool value) =>
      _prefs.setBool(_kRemember, value);

  Future<String> getSavedEmail() async =>
      await _prefs.getString(_kEmail) ?? '';

  Future<void> saveEmail(String email) => _prefs.setString(_kEmail, email);

  Future<void> clearEmail() => _prefs.remove(_kEmail);

  // Pengaturan pengingat
  Future<int> getReminderLead() async => await _prefs.getInt(_kLead) ?? 30;

  Future<void> setReminderLead(int minutes) => _prefs.setInt(_kLead, minutes);

  Future<bool> getNotifSound() async => await _prefs.getBool(_kSound) ?? true;

  Future<void> setNotifSound(bool value) => _prefs.setBool(_kSound, value);

  Future<String> getScheduleView() async =>
      await _prefs.getString(_kView) ?? 'harian';

  Future<void> setScheduleView(String value) =>
      _prefs.setString(_kView, value);

  Future<List<String>> getStudyDays() async =>
      await _prefs.getStringList(_kDays) ?? <String>[];

  Future<void> setStudyDays(List<String> days) =>
      _prefs.setStringList(_kDays, days);
}
