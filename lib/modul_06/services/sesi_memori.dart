import '../models/sesi_pengguna.dart';

/// Penyimpanan sesi di memori proses (RAM).
/// Sesi akan bertahan selama aplikasi hidup, dan hilang saat proses dimatikan.
class SesiMemori {
  SesiPengguna? _sesi;
  int jumlahPenulisan = 0; // Dipakai pengujian.

  SesiPengguna? baca() => _sesi;
  bool get adaSesi => _sesi != null;

  Future<void> simpan(SesiPengguna sesi) async {
    _sesi = sesi;
    jumlahPenulisan++;
  }

  Future<void> hapus() async {
    _sesi = null;
  }
}
