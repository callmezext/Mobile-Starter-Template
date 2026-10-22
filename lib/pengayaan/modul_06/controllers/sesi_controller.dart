import 'package:flutter/foundation.dart';
import 'package:poliwangi_mobile_starter/modul_06/models/sesi_pengguna.dart';
import 'package:poliwangi_mobile_starter/modul_06/services/auth_api.dart';
import '../repositories/sesi_repository.dart';

enum StatusSesi { memeriksa, keluar, memproses, masuk, gagal, kedaluwarsa }

/// Pengendali sesi terpusat berbasis ChangeNotifier (Fase B).
/// Layar tidak lagi menyimpan state kebenaran sendiri; melainkan mengamati controller ini.
class SesiController extends ChangeNotifier {
  SesiRepository _repository;
  final AuthApi api;
  final DateTime Function() jam;

  StatusSesi _status = StatusSesi.memeriksa;
  String? _pesan;
  SesiPengguna? _sesi;

  SesiController({
    required SesiRepository repository,
    required this.api,
    this.jam = DateTime.now,
  }) : _repository = repository;

  StatusSesi get status => _status;
  String? get pesan => _pesan;
  SesiPengguna? get sesi => _sesi;
  SesiRepository get repository => _repository;
  bool get adaSesi => _sesi != null;

  void _ubah(
    StatusSesi statusBaru, {
    SesiPengguna? sesi,
    String? pesan,
    bool bersihkanPesan = false,
  }) {
    _status = statusBaru;
    if (sesi != null || statusBaru == StatusSesi.keluar) {
      _sesi = sesi;
    }
    if (bersihkanPesan) {
      _pesan = null;
    } else if (pesan != null) {
      _pesan = pesan;
    }
    notifyListeners();
  }

  /// Memulihkan sesi dari penyimpanan aktif saat aplikasi dibuka.
  Future<void> pulihkan() async {
    _ubah(StatusSesi.memeriksa, bersihkanPesan: true);
    try {
      final SesiPengguna? tersimpan = await _repository.baca();
      if (tersimpan == null) {
        _ubah(StatusSesi.keluar, sesi: null);
        return;
      }

      if (tersimpan.sudahKedaluwarsa(jam())) {
        await _repository.hapus(); // Sesi mati dibuang, bukan dibiarkan.
        _sesi = null;
        _ubah(
          StatusSesi.kedaluwarsa,
          pesan: 'Sesi Anda sudah berakhir. Silakan masuk kembali.',
        );
        return;
      }

      _ubah(StatusSesi.masuk, sesi: tersimpan);
    } catch (e) {
      debugPrint('SesiController: Gagal membaca penyimpanan ($e)');
      _ubah(StatusSesi.keluar, sesi: null);
    }
  }

  /// Memproses login ke API dan menyimpan sesi ke repository.
  Future<void> masuk({required String email, required String sandi}) async {
    if (_status == StatusSesi.memproses) return;
    _ubah(StatusSesi.memproses, bersihkanPesan: true);

    try {
      final SesiPengguna hasil = await api.masuk(email: email, sandi: sandi);
      await _repository.simpan(hasil);
      _ubah(StatusSesi.masuk, sesi: hasil);
    } on AuthException catch (e) {
      _ubah(StatusSesi.gagal, pesan: e.pesan);
    } catch (e) {
      _ubah(
        StatusSesi.gagal,
        pesan: 'Terjadi kesalahan tak terduga. Coba lagi.',
      );
    }
  }

  /// Menghapus sesi dan beralih ke state keluar.
  Future<void> keluar() async {
    await _repository.hapus();
    _ubah(StatusSesi.keluar, sesi: null, bersihkanPesan: true);
  }

  /// Memperbarui masa berlaku sesi ("refresh token") jika sesi belum mati.
  Future<void> perbaruiSesi({
    Duration masaBerlaku = const Duration(hours: 2),
  }) async {
    final SesiPengguna? sekarang = _sesi;
    if (sekarang == null) return;

    if (sekarang.sudahKedaluwarsa(jam())) {
      await _repository.hapus();
      _sesi = null;
      _ubah(
        StatusSesi.kedaluwarsa,
        pesan: 'Sesi sudah berakhir dan tidak dapat diperbarui.',
      );
      return;
    }

    final SesiPengguna baru =
        await api.perbaruiSesi(sekarang, masaBerlaku: masaBerlaku);
    await _repository.simpan(baru);
    _ubah(StatusSesi.masuk, sesi: baru);
  }

  /// Mengganti repository penyimpanan secara dinamis untuk perbandingan.
  Future<void> gantiRepository(SesiRepository repoBaru) async {
    _repository = repoBaru;
    await pulihkan();
  }
}
