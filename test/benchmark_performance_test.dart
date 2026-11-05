import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poliwangi_mobile_starter/module_11/modul_11_app.dart';

void main() {
  group('Benchmark Performa Modul 11: Optimasi Penyaringan Data', () {
    const daftarMataKuliah = [
      'Pemrograman Mobile',
      'Basis Data',
      'Jaringan Komputer',
      'Rekayasa Perangkat Lunak',
      'Sistem Operasi',
      'Kecerdasan Buatan',
      'Pemrograman Web',
      'Analisis dan Perancangan Sistem',
    ];

    late List<TugasPerforma> data1000;

    setUpAll(() {
      data1000 = List<TugasPerforma>.generate(
        1000,
        (index) => TugasPerforma(
          nomor: index + 1,
          mataKuliah: daftarMataKuliah[index % 8],
          status: (index + 1) % 4 == 0 ? StatusTugas.selesai : StatusTugas.aktif,
        ),
        growable: false,
      );
    });

    List<TugasPerforma> saringTugas({
      required List<TugasPerforma> sumber,
      StatusTugas? filterStatus,
      String? filterMataKuliah,
      String kueri = '',
    }) {
      final kueriLower = kueri.toLowerCase();
      return sumber.where((tugas) {
        final cocokStatus = filterStatus == null || tugas.status == filterStatus;
        final cocokMataKuliah =
            filterMataKuliah == null || tugas.mataKuliah == filterMataKuliah;
        final cocokTeks =
            '${tugas.judul} ${tugas.mataKuliah}'.toLowerCase().contains(kueriLower);
        return cocokStatus && cocokMataKuliah && cocokTeks;
      }).toList(growable: false);
    }

    test(
      '1. Ukur waktu eksekusi penyaringan 1.000 data terhadap 8 variasi filter mata kuliah (< 5ms)',
      () {
        expect(data1000.length, equals(1000));

        // Pemanasan (Warm-up) VM JIT
        for (var i = 0; i < 20; i++) {
          saringTugas(sumber: data1000, filterMataKuliah: daftarMataKuliah[i % 8]);
        }

        const iterasi = 100;
        final hasilWaktu = <String, double>{};

        for (final mataKuliah in daftarMataKuliah) {
          final stopwatch = Stopwatch()..start();

          for (var i = 0; i < iterasi; i++) {
            final hasil = saringTugas(sumber: data1000, filterMataKuliah: mataKuliah);
            expect(hasil.length, equals(125));
          }

          stopwatch.stop();

          final rataRataUs = stopwatch.elapsedMicroseconds / iterasi;
          final rataRataMs = rataRataUs / 1000.0;
          hasilWaktu[mataKuliah] = rataRataMs;

          // Memastikan waktu komputasi filter lokal berada jauh di bawah anggaran frame (< 5ms per run)
          expect(
            rataRataMs,
            lessThan(5.0),
            reason:
                'Penyaringan mata kuliah $mataKuliah: ${rataRataMs.toStringAsFixed(3)}ms (wajib < 5.0ms)',
          );
        }

        debugPrint('--- Hasil Benchmark 8 Variasi Mata Kuliah (100 iterasi x 1000 data) ---');
        hasilWaktu.forEach((mk, ms) {
          debugPrint('  * $mk: ${ms.toStringAsFixed(3)} ms/run (budget: < 5.0 ms)');
        });
      },
    );

    test(
      '2. Ukur waktu eksekusi pencarian teks kueri spesifik (< 5ms)',
      () {
        final skenarioKueri = <String, int>{
          '0002': 1,
          'tugas praktikum 0500': 1,
          '1000': 1,
          'Kecerdasan Buatan': 125,
          'Basis Data': 125,
          'kueri tidak cocok sama sekali xyz': 0,
        };

        // Pemanasan (Warm-up)
        for (final kueri in skenarioKueri.keys) {
          saringTugas(sumber: data1000, kueri: kueri);
        }

        const iterasi = 100;
        final hasilWaktu = <String, double>{};

        for (final entry in skenarioKueri.entries) {
          final kueri = entry.key;
          final ekspektasiJumlah = entry.value;

          final stopwatch = Stopwatch()..start();

          for (var i = 0; i < iterasi; i++) {
            final hasil = saringTugas(sumber: data1000, kueri: kueri);
            expect(hasil.length, equals(ekspektasiJumlah));
          }

          stopwatch.stop();

          final rataRataUs = stopwatch.elapsedMicroseconds / iterasi;
          final rataRataMs = rataRataUs / 1000.0;
          hasilWaktu[kueri] = rataRataMs;

          // Memastikan waktu komputasi filter pencarian berada jauh di bawah anggaran frame (< 5ms per run)
          expect(
            rataRataMs,
            lessThan(5.0),
            reason:
                'Pencarian kueri "$kueri": ${rataRataMs.toStringAsFixed(3)}ms (wajib < 5.0ms)',
          );
        }

        debugPrint('--- Hasil Benchmark Pencarian Teks Spesifik (100 iterasi x 1000 data) ---');
        hasilWaktu.forEach((kueri, ms) {
          debugPrint('  * Kueri "$kueri": ${ms.toStringAsFixed(3)} ms/run (budget: < 5.0 ms)');
        });
      },
    );

    test(
      '3. Ukur waktu eksekusi kombinasi multi-filter (status, mata kuliah, teks)',
      () {
        const iterasi = 100;

        // Kombinasi 1: Status Selesai + RPL (125 item)
        final sw1 = Stopwatch()..start();
        for (var i = 0; i < iterasi; i++) {
          final hasil = saringTugas(
            sumber: data1000,
            filterStatus: StatusTugas.selesai,
            filterMataKuliah: 'Rekayasa Perangkat Lunak',
          );
          expect(hasil.length, equals(125));
        }
        sw1.stop();
        final ms1 = (sw1.elapsedMicroseconds / iterasi) / 1000.0;
        expect(ms1, lessThan(5.0));

        // Kombinasi 2: Status Aktif + RPL (0 item)
        final sw2 = Stopwatch()..start();
        for (var i = 0; i < iterasi; i++) {
          final hasil = saringTugas(
            sumber: data1000,
            filterStatus: StatusTugas.aktif,
            filterMataKuliah: 'Rekayasa Perangkat Lunak',
          );
          expect(hasil.length, equals(0));
        }
        sw2.stop();
        final ms2 = (sw2.elapsedMicroseconds / iterasi) / 1000.0;
        expect(ms2, lessThan(5.0));

        // Kombinasi 3: Filter mata kuliah + teks spesifik '0100' (1 item)
        final sw3 = Stopwatch()..start();
        for (var i = 0; i < iterasi; i++) {
          final hasil = saringTugas(
            sumber: data1000,
            filterMataKuliah: 'Rekayasa Perangkat Lunak',
            kueri: '0100',
          );
          expect(hasil.length, equals(1));
        }
        sw3.stop();
        final ms3 = (sw3.elapsedMicroseconds / iterasi) / 1000.0;
        expect(ms3, lessThan(5.0));

        debugPrint('--- Hasil Benchmark Kombinasi Multi-Filter ---');
        debugPrint('  * Status Selesai + RPL: ${ms1.toStringAsFixed(3)} ms/run');
        debugPrint('  * Status Aktif + RPL: ${ms2.toStringAsFixed(3)} ms/run');
        debugPrint('  * RPL + Kueri "0100": ${ms3.toStringAsFixed(3)} ms/run');
      },
    );

    test(
      '4. Pastikan waktu komputasi filter lokal berada jauh di bawah anggaran frame 16.6ms (< 5ms per run)',
      () {
        // Pengujian single run terisolasi tanpa loop iterasi rata-rata
        final stopwatch = Stopwatch()..start();
        final hasil = saringTugas(
          sumber: data1000,
          filterStatus: StatusTugas.aktif,
          filterMataKuliah: 'Pemrograman Mobile',
          kueri: 'tugas praktikum 0001',
        );
        stopwatch.stop();

        expect(hasil.length, equals(1));

        final durasiMs = stopwatch.elapsedMicroseconds / 1000.0;

        // Validasi kriteria bahwa latensi filter lokal berada jauh di bawah anggaran frame (< 5ms)
        expect(
          durasiMs,
          lessThan(5.0),
          reason:
              'Waktu komputasi single run (${durasiMs.toStringAsFixed(3)}ms) melampaui batas 5ms',
        );

        // Menghitung sisa frame headroom pada target 60 FPS (16.6 ms) dan 120 FPS (8.3 ms)
        final headroom60Fps = 16.6 - durasiMs;
        final headroom120Fps = 8.3 - durasiMs;

        expect(headroom60Fps, greaterThan(11.6));
        expect(headroom120Fps, greaterThan(3.3));

        debugPrint('--- Analisis Anggaran Frame Rendering ---');
        debugPrint('  * Single Run Latency: ${durasiMs.toStringAsFixed(3)} ms');
        debugPrint('  * Headroom 60 FPS (budget 16.6 ms): ${headroom60Fps.toStringAsFixed(3)} ms');
        debugPrint('  * Headroom 120 FPS (budget 8.3 ms): ${headroom120Fps.toStringAsFixed(3)} ms');
      },
    );

    testWidgets(
      '5. Verifikasi fungsionalitas UI Modul11App saat filter dan pencarian aktif',
      (WidgetTester tester) async {
        await tester.pumpWidget(const Modul11App());
        await tester.pumpAndSettle();

        expect(find.text('Menampilkan 1000 dari 1000 tugas'), findsOneWidget);

        // Simulasi pencarian '0002'
        final searchField = find.byKey(const ValueKey('task-search'));
        await tester.enterText(searchField, '0002');
        await tester.pumpAndSettle();

        expect(find.text('Menampilkan 1 dari 1000 tugas'), findsOneWidget);
        expect(find.text('Tugas praktikum 0002'), findsOneWidget);

        // Bersihkan pencarian
        final clearBtn = find.byKey(const ValueKey('clear-search'));
        await tester.tap(clearBtn);
        await tester.pumpAndSettle();
        expect(find.text('Menampilkan 1000 dari 1000 tugas'), findsOneWidget);

        // Simulasi filter dropdown mata kuliah
        final dropdownFinder = find.byKey(const ValueKey('filter-mata-kuliah'));
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Basis Data').last, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.text('Menampilkan 125 dari 1000 tugas'), findsOneWidget);
      },
    );
  });
}
