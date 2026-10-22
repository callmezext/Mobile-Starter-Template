/// Kontrak abstraksi penyimpanan rahasia platform.
/// Memisahkan antarmuka dari plugin FlutterSecureStorage nyata agar
/// kode dapat diuji secara independen tanpa plugin platform di flutter test.
abstract class PenyimpananAman {
  Future<void> tulis(String kunci, String nilai);
  Future<String?> baca(String kunci);
  Future<void> hapus(String kunci);

  /// Antarmuka demo untuk membandingkan kemampuan adapter; bukan alat forensik.
  Future<String?> bacaMentah(String kunci);
}
