import 'package:poliwangi_mobile_starter/modul_06/models/sesi_pengguna.dart';
import 'package:poliwangi_mobile_starter/modul_06/services/sesi_memori.dart';
import 'sesi_repository.dart';

/// Implementasi repository yang membungkus SesiMemori dari Fase A.
class MemoriSesiRepository implements SesiRepository {
  final SesiMemori sesiMemori;

  MemoriSesiRepository(this.sesiMemori);

  @override
  String get nama => 'Memori';

  @override
  String get keterangan => 'Hanya tersimpan di memori RAM proses (Fase A)';

  @override
  bool get bertahanSetelahRestart => false;

  @override
  Future<SesiPengguna?> baca() async => sesiMemori.baca();

  @override
  Future<void> simpan(SesiPengguna sesi) => sesiMemori.simpan(sesi);

  @override
  Future<void> hapus() => sesiMemori.hapus();

  @override
  Future<bool> adaSesi() async => sesiMemori.adaSesi;

  @override
  Future<String?> intipMentah() async => null;
}
