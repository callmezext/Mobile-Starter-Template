import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'penyimpanan_aman.dart';

/// Implementasi PenyimpananAman menggunakan plugin platform FlutterSecureStorage.
/// Mendukung fallback web bila plugin platform channel tidak tersedia di environment tertentu.
class PenyimpananAmanPlatform implements PenyimpananAman {
  final FlutterSecureStorage _storage;
  final Map<String, String> _webFallback = {};

  PenyimpananAmanPlatform({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> tulis(String kunci, String nilai) async {
    try {
      await _storage.write(key: kunci, value: nilai);
    } catch (_) {
      _webFallback[kunci] = nilai;
    }
  }

  @override
  Future<String?> baca(String kunci) async {
    try {
      return await _storage.read(key: kunci);
    } catch (_) {
      return _webFallback[kunci];
    }
  }

  @override
  Future<void> hapus(String kunci) async {
    try {
      await _storage.delete(key: kunci);
    } catch (_) {
      _webFallback.remove(kunci);
    }
  }

  @override
  Future<String?> bacaMentah(String kunci) async {
    // Ilustrasi batas API: plugin tidak menyediakan pembacaan mentah
    // melalui kontrak ini. Ini bukan pemeriksaan forensik isi disk.
    return null;
  }
}
