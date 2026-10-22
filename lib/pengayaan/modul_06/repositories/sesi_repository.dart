import 'package:poliwangi_mobile_starter/modul_06/models/sesi_pengguna.dart';

/// Kontrak repository sesi untuk membandingkan karakteristik penyimpanan.
/// Berkas ini tidak mengimpor shared_preferences maupun flutter_secure_storage.
abstract class SesiRepository {
  String get nama;
  String get keterangan;
  bool get bertahanSetelahRestart;

  Future<SesiPengguna?> baca();
  Future<void> simpan(SesiPengguna sesi);
  Future<void> hapus();
  Future<bool> adaSesi();

  /// Demonstrasi batas API untuk menguji kerentanan penyimpanan plaintext.
  Future<String?> intipMentah();
}
