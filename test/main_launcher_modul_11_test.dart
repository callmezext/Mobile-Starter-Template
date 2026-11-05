import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poliwangi_mobile_starter/main.dart';
import 'package:poliwangi_mobile_starter/module_11/modul_11_app.dart';

void main() {
  group('Launcher Modul 11 & Konfigurasi Token', () {
    test('1. Konfigurasi token kelas Modul 07 dan batas aktif Modul 11 valid', () {
      expect(ModuleLauncherScreen.activeModuleUntil, greaterThanOrEqualTo(11));
      expect(
        ModuleLauncherScreen.modulePasscodes[7],
        isNotNull,
      );
      expect(
        ModuleLauncherScreen.modulePasscodes[7],
        contains('M07-DC4D2C19032EDA98D79D'),
      );
    });

    testWidgets(
      '2. Membuka Modul 11 dari launcher berhasil bernavigasi ke LayarDaftarTugasPerforma',
      (WidgetTester tester) async {
        await tester.pumpWidget(const PoliwangiStarterApp());
        await tester.pumpAndSettle();
        // Cari kartu Modul 11 di launcher (scroll hingga masuk viewport)
        final modul11Finder = find.text('Performance Optimization');
        await tester.scrollUntilVisible(
          modul11Finder,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(modul11Finder, findsOneWidget);

        // Tekan kartu Modul 11
        await tester.tap(modul11Finder);
        await tester.pumpAndSettle();

        // Verifikasi bahwa layar LayarDaftarTugasPerforma terbuka
        expect(find.byType(LayarDaftarTugasPerforma), findsOneWidget);
        expect(find.text('Tugas Kuliah'), findsOneWidget);
        expect(find.byKey(const ValueKey('task-list')), findsOneWidget);

        // Verifikasi navigasi kembali ke launcher
        final backButton = find.byType(BackButton);
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Verifikasi kembali ke launcher
        expect(find.byType(ModuleLauncherScreen), findsOneWidget);
      },
    );
  });
}
