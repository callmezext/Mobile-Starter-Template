import 'dart:convert';
import 'package:poliwangi_mobile_starter/modul_06/models/sesi_pengguna.dart';
import '../storage/penyimpanan_aman.dart';
import '../storage/penyimpanan_aman_platform.dart';
import 'sesi_repository.dart';

/// Repository sesi menggunakan PenyimpananAman (Keystore di Android, Keychain di iOS).
/// Bertahan setelah restart, dan data dienkripsi oleh platform.
class AmanSesiRepository implements SesiRepository {
  static const String kunciSesi = 'modul_06_sesi_aman';
  final PenyimpananAman penyimpanan;

  AmanSesiRepository({PenyimpananAman? penyimpanan})
      : penyimpanan = penyimpanan ?? PenyimpananAmanPlatform();

  @override
  String get nama => 'Aman';

  @override
  String get keterangan =>
      'Penyimpanan Aman Platform (Keystore / Keychain / WebCrypto)';

  @override
  bool get bertahanSetelahRestart => true;

  @override
  Future<SesiPengguna?> baca() async {
    final str = await penyimpanan.baca(kunciSesi);
    if (str == null || str.isEmpty) return null;
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return SesiPengguna.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> simpan(SesiPengguna sesi) async {
    await penyimpanan.tulis(kunciSesi, jsonEncode(sesi.toJson()));
  }

  @override
  Future<void> hapus() async {
    await penyimpanan.hapus(kunciSesi);
  }

  @override
  Future<bool> adaSesi() async {
    final str = await penyimpanan.baca(kunciSesi);
    return str != null && str.isNotEmpty;
  }

  @override
  Future<String?> intipMentah() => penyimpanan.bacaMentah(kunciSesi);
}
