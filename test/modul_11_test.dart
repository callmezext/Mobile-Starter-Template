import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poliwangi_mobile_starter/module_11/modul_11_app.dart';

void main() {
  group('Modul 11: Optimasi Performa Daftar Tugas', () {
    testWidgets(
      '1. ListView.builder hanya membangun widget di viewport, jauh lebih sedikit dari 1.000 data',
      (WidgetTester tester) async {
        await tester.pumpWidget(const Modul11App());
        await tester.pumpAndSettle();

        // Verifikasi teks total tugas awal
        expect(find.byKey(const ValueKey('result-count')), findsOneWidget);
        expect(find.text('Menampilkan 1000 dari 1000 tugas'), findsOneWidget);

        // Verifikasi ListView.builder ada di layar
        expect(find.byKey(const ValueKey('task-list')), findsOneWidget);

        // Verifikasi jumlah Card yang terbentuk di viewport jauh di bawah 1.000
        final cardCount = find.byType(Card).evaluate().length;
        expect(cardCount, greaterThan(0));
        expect(cardCount, lessThan(30));
      },
    );

    testWidgets(
      '2. Pengguna dapat mencari tugas spesifik dan membersihkan pencarian',
      (WidgetTester tester) async {
        await tester.pumpWidget(const Modul11App());
        await tester.pumpAndSettle();

        // Cari tugas praktikum 0002
        final searchField = find.byKey(const ValueKey('task-search'));
        await tester.enterText(searchField, 'tugas praktikum 0002');
        await tester.pumpAndSettle();

        // Hasil harus tepat 1 tugas
        expect(find.text('Menampilkan 1 dari 1000 tugas'), findsOneWidget);
        expect(find.text('Tugas praktikum 0002'), findsOneWidget);

        // Bersihkan pencarian via tombol clear
        final clearBtn = find.byKey(const ValueKey('clear-search'));
        expect(clearBtn, findsOneWidget);
        await tester.tap(clearBtn);
        await tester.pumpAndSettle();

        // Jumlah tugas kembali penuh 1000
        expect(find.text('Menampilkan 1000 dari 1000 tugas'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Filter status Aktif dan Selesai mengubah jumlah hasil dengan tepat',
      (WidgetTester tester) async {
        await tester.pumpWidget(const Modul11App());
        await tester.pumpAndSettle();

        // Filter status Selesai: tepat 250 dari 1.000 (setiap tugas kelipatan 4)
        final filterSelesai = find.widgetWithText(FilterChip, 'Selesai');
        await tester.tap(filterSelesai);
        await tester.pumpAndSettle();
        expect(find.text('Menampilkan 250 dari 1000 tugas'), findsOneWidget);

        // Filter status Aktif: 750 dari 1.000
        final filterAktif = find.widgetWithText(FilterChip, 'Aktif');
        await tester.tap(filterAktif);
        await tester.pumpAndSettle();
        expect(find.text('Menampilkan 750 dari 1000 tugas'), findsOneWidget);

        // Kembali ke Semua: 1.000 tugas
        final filterSemua = find.widgetWithText(FilterChip, 'Semua');
        await tester.tap(filterSemua);
        await tester.pumpAndSettle();
        expect(find.text('Menampilkan 1000 dari 1000 tugas'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Latihan Mandiri: Filter mata kuliah mengubah jumlah hasil sesuai pilihan',
      (WidgetTester tester) async {
        await tester.pumpWidget(const Modul11App());
        await tester.pumpAndSettle();

        // Buka dropdown mata kuliah
        final dropdownFinder = find.byKey(const ValueKey('filter-mata-kuliah'));
        expect(dropdownFinder, findsOneWidget);
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();

        // Pilih mata kuliah 'Basis Data' (1000 tugas dibagi 8 mata kuliah = 125 tugas per mata kuliah)
        await tester.tap(find.text('Basis Data').last, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Hasil harus tepat 125 tugas
        expect(find.text('Menampilkan 125 dari 1000 tugas'), findsOneWidget);

        // Buka kembali dropdown dan kembalikan ke Semua Mata Kuliah
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('Semua Mata Kuliah').last,
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(find.text('Menampilkan 1000 dari 1000 tugas'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Menampilkan pesan kosong ketika kueri pencarian tidak menemukan tugas',
      (WidgetTester tester) async {
        await tester.pumpWidget(const Modul11App());
        await tester.pumpAndSettle();

        final searchField = find.byKey(const ValueKey('task-search'));
        await tester.enterText(searchField, 'kueri tidak cocok sama sekali xyz');
        await tester.pumpAndSettle();

        expect(find.text('Menampilkan 0 dari 1000 tugas'), findsOneWidget);
        expect(find.text('Tidak ada tugas yang cocok.'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Daftar dapat digulir hingga item terakhir (tugas 1000)',
      (WidgetTester tester) async {
        await tester.pumpWidget(const Modul11App());
        await tester.pumpAndSettle();

        final listScrollable = find.descendant(
          of: find.byKey(const ValueKey('task-list')),
          matching: find.byType(Scrollable),
        );
        final item1000 = find.byKey(const ValueKey('task-card-1000'));

        // Gulir sampai item 1000 ditemukan di dalam viewport
        await tester.scrollUntilVisible(
          item1000,
          500.0,
          scrollable: listScrollable,
          maxScrolls: 250,
        );
        await tester.pumpAndSettle();

        expect(item1000, findsOneWidget);
        expect(find.text('Tugas praktikum 1000'), findsOneWidget);
      },
    );

    testWidgets(
      '7. Kombinasi filter status dan mata kuliah menghasilkan data deterministik',
      (WidgetTester tester) async {
        await tester.pumpWidget(const Modul11App());
        await tester.pumpAndSettle();

        // Filter mata kuliah 'Rekayasa Perangkat Lunak'
        // index % 8 == 3 -> nomor = index + 1 -> nomor % 8 == 4 (selalu kelipatan 4)
        // Semua tugas Rekayasa Perangkat Lunak otomatis berstatus 'Selesai' (125 tugas)
        final dropdownFinder = find.byKey(const ValueKey('filter-mata-kuliah'));
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('Rekayasa Perangkat Lunak').last,
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Filter status 'Selesai'
        final filterSelesai = find.widgetWithText(FilterChip, 'Selesai');
        await tester.tap(filterSelesai);
        await tester.pumpAndSettle();

        // Hasil: tetap 125 tugas karena seluruh 125 tugas RPL berstatus selesai
        expect(find.text('Menampilkan 125 dari 1000 tugas'), findsOneWidget);

        // Filter status 'Aktif'
        final filterAktif = find.widgetWithText(FilterChip, 'Aktif');
        await tester.tap(filterAktif);
        await tester.pumpAndSettle();

        // Hasil: 0 tugas karena tidak ada tugas RPL yang aktif
        expect(find.text('Menampilkan 0 dari 1000 tugas'), findsOneWidget);
        expect(find.text('Tidak ada tugas yang cocok.'), findsOneWidget);
      },
    );

    testWidgets(
      '8. Kombinasi pencarian teks dengan filter mata kuliah menyaring secara akurat',
      (WidgetTester tester) async {
        await tester.pumpWidget(const Modul11App());
        await tester.pumpAndSettle();

        // Filter mata kuliah 'Rekayasa Perangkat Lunak'
        final dropdownFinder = find.byKey(const ValueKey('filter-mata-kuliah'));
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('Rekayasa Perangkat Lunak').last,
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(find.text('Menampilkan 125 dari 1000 tugas'), findsOneWidget);

        // Masukkan kata kunci pencarian nomor tugas spesifik '0100'
        // Nomor 100 % 8 = 4 -> Tugas praktikum 0100 di RPL
        final searchField = find.byKey(const ValueKey('task-search'));
        await tester.enterText(searchField, '0100');
        await tester.pumpAndSettle();

        // Tepat 1 hasil ditemukan
        expect(find.text('Menampilkan 1 dari 1000 tugas'), findsOneWidget);
        expect(find.text('Tugas praktikum 0100'), findsOneWidget);
      },
    );
  });
}
