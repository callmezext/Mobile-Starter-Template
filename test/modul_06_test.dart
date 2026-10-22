import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poliwangi_mobile_starter/modul_06/models/sesi_pengguna.dart';
import 'package:poliwangi_mobile_starter/modul_06/screens/login_screen.dart';
import 'package:poliwangi_mobile_starter/modul_06/services/auth_api.dart';
import 'package:poliwangi_mobile_starter/modul_06/services/sesi_memori.dart';
import 'package:poliwangi_mobile_starter/pengayaan/modul_06/controllers/sesi_controller.dart';
import 'package:poliwangi_mobile_starter/pengayaan/modul_06/repositories/aman_sesi_repository.dart';
import 'package:poliwangi_mobile_starter/pengayaan/modul_06/repositories/memori_sesi_repository.dart';
import 'package:poliwangi_mobile_starter/pengayaan/modul_06/storage/penyimpanan_aman.dart';

class FakePenyimpananAman implements PenyimpananAman {
  final Map<String, String> _data = {};

  @override
  Future<String?> baca(String kunci) async => _data[kunci];

  @override
  Future<void> tulis(String kunci, String nilai) async {
    _data[kunci] = nilai;
  }

  @override
  Future<void> hapus(String kunci) async {
    _data.remove(kunci);
  }

  @override
  Future<String?> bacaMentah(String kunci) async => null;
}

void main() {
  group('Fase A: Autentikasi & Sesi Memori', () {
    test('1. Model SesiPengguna serialization dan kedaluwarsa berfungsi', () {
      final now = DateTime(2026, 9, 21, 8, 0);
      final sesi = SesiPengguna.contoh(sekarang: now);

      final json = sesi.toJson();
      expect(json['email'], 'student@trpl.test');
      expect(json['peran'], 'mahasiswa');

      final pulih = SesiPengguna.fromJson(json);
      expect(pulih.token, sesi.token);
      expect(pulih.email, sesi.email);
      expect(pulih.nama, sesi.nama);

      // Sisa waktu
      expect(sesi.sisaWaktu(now).inHours, 2);
      expect(sesi.sudahKedaluwarsa(now.add(const Duration(hours: 1))), isFalse);
      expect(sesi.sudahKedaluwarsa(now.add(const Duration(hours: 3))), isTrue);
    });

    test('2. AuthApi menangani berbagai skenario kredensial secara deterministik',
        () async {
      const api = AuthApi(tunda: Duration.zero);

      // Kredensial benar
      final sukses = await api.masuk(
        email: 'student@trpl.test',
        sandi: 'belajar123',
      );
      expect(sukses.email, 'student@trpl.test');
      expect(sukses.token.startsWith('dummy.'), isTrue);

      // Sandi salah (401)
      expect(
        () => api.masuk(email: 'student@trpl.test', sandi: 'salah123'),
        throwsA(isA<AuthException>().having((e) => e.kode, 'kode', 401)),
      );

      // Akun terkunci (423)
      expect(
        () => api.masuk(email: 'terkunci@trpl.test', sandi: 'bebas'),
        throwsA(isA<AuthException>().having((e) => e.kode, 'kode', 423)),
      );

      // Gangguan server (503)
      expect(
        () => api.masuk(email: 'gangguan@trpl.test', sandi: 'bebas'),
        throwsA(isA<AuthException>().having((e) => e.kode, 'kode', 503)),
      );

      // Akun belum aktif (403 - Latihan Mandiri 1)
      expect(
        () => api.masuk(email: 'belumaktif@trpl.test', sandi: 'bebas'),
        throwsA(isA<AuthException>().having((e) => e.kode, 'kode', 403)),
      );
    });

    test('3. SesiMemori menyimpan, membaca, dan menghapus sesi di RAM',
        () async {
      final memori = SesiMemori();
      expect(memori.adaSesi, isFalse);
      expect(memori.baca(), isNull);

      final sesi = SesiPengguna.contoh();
      await memori.simpan(sesi);
      expect(memori.adaSesi, isTrue);
      expect(memori.baca()?.token, sesi.token);
      expect(memori.jumlahPenulisan, 1);

      await memori.hapus();
      expect(memori.adaSesi, isFalse);
      expect(memori.baca(), isNull);
    });

    testWidgets('4. Layar Login memvalidasi form dan memproses login berhasil',
        (tester) async {
      final memori = SesiMemori();
      const api = AuthApi(tunda: Duration.zero);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(api: api, sesiMemori: memori),
        ),
      );
      await tester.pumpAndSettle();

      // Form awal muncul
      expect(find.text('Masuk ke Portal Akademik'), findsOneWidget);

      // Tekan masuk dengan form kosong -> validasi muncul
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();
      expect(find.text('Email wajib diisi.'), findsOneWidget);

      // Isi form dengan kredensial demo
      await tester.enterText(
          find.byType(TextFormField).first, 'student@trpl.test');
      await tester.enterText(
          find.byType(TextFormField).last, 'belajar123');

      // Tekan tombol Masuk
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      // Berpindah ke beranda
      expect(find.text('Beranda Mahasiswa'), findsOneWidget);
      expect(find.text('Mahasiswa TRPL'), findsOneWidget);
      expect(memori.adaSesi, isTrue);

      // Tekan Keluar
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      // Kembali ke form login & sesi di memori terhapus
      expect(find.text('Masuk ke Portal Akademik'), findsOneWidget);
      expect(memori.adaSesi, isFalse);
    });
  });

  group('Fase B: Pengayaan & Sesi Aman', () {
    test('1. MemoriSesiRepository vs AmanSesiRepository intipMentah behavior',
        () async {
      final memoriRepo = MemoriSesiRepository(SesiMemori());
      expect(await memoriRepo.intipMentah(), isNull);

      final fakeStorage = FakePenyimpananAman();
      final amanRepo = AmanSesiRepository(penyimpanan: fakeStorage);

      final sesi = SesiPengguna.contoh();
      await amanRepo.simpan(sesi);
      expect(await amanRepo.adaSesi(), isTrue);

      // Pembacaan mentah adapter aman menghasilkan null (rahasia terlindungi)
      expect(await amanRepo.intipMentah(), isNull);

      final pulih = await amanRepo.baca();
      expect(pulih?.token, sesi.token);

      await amanRepo.hapus();
      expect(await amanRepo.adaSesi(), isFalse);
    });

    test('2. SesiController mengelola siklus hidup sesi dan pembaruan',
        () async {
      final fakeStorage = FakePenyimpananAman();
      final amanRepo = AmanSesiRepository(penyimpanan: fakeStorage);
      const api = AuthApi(tunda: Duration.zero);

      final controller = SesiController(repository: amanRepo, api: api);
      await controller.pulihkan();
      expect(controller.status, StatusSesi.keluar);

      // Login
      await controller.masuk(
        email: 'student@trpl.test',
        sandi: 'belajar123',
      );
      expect(controller.status, StatusSesi.masuk);
      expect(controller.adaSesi, isTrue);

      // Refresh token
      await controller.perbaruiSesi();
      expect(controller.status, StatusSesi.masuk);

      // Logout
      await controller.keluar();
      expect(controller.status, StatusSesi.keluar);
      expect(controller.adaSesi, isFalse);
    });
  });
}
