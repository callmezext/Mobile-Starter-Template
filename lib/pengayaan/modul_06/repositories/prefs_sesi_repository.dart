import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poliwangi_mobile_starter/modul_06/models/sesi_pengguna.dart';
import 'sesi_repository.dart';

/// Repository sesi menggunakan SharedPreferences.
/// Bertahan setelah restart, namun data tersimpan dalam bentuk teks polos (plaintext).
class PrefsSesiRepository implements SesiRepository {
  static const String kunciSesi = 'modul_06_sesi_pengguna';
  final Future<SharedPreferences> _prefs;

  PrefsSesiRepository({Future<SharedPreferences>? prefs})
      : _prefs = prefs ?? SharedPreferences.getInstance();

  @override
  String get nama => 'Prefs';

  @override
  String get keterangan => 'SharedPreferences (Persisten, namun Plaintext)';

  @override
  bool get bertahanSetelahRestart => true;

  @override
  Future<SesiPengguna?> baca() async {
    final prefs = await _prefs;
    final jsonStr = prefs.getString(kunciSesi);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return SesiPengguna.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> simpan(SesiPengguna sesi) async {
    final prefs = await _prefs;
    await prefs.setString(kunciSesi, jsonEncode(sesi.toJson()));
  }

  @override
  Future<void> hapus() async {
    final prefs = await _prefs;
    await prefs.remove(kunciSesi);
  }

  @override
  Future<bool> adaSesi() async {
    final prefs = await _prefs;
    return prefs.containsKey(kunciSesi);
  }

  @override
  Future<String?> intipMentah() async {
    final prefs = await _prefs;
    return prefs.getString(kunciSesi);
  }
}
