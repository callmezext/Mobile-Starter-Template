import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poliwangi_mobile_starter/module_11/modul_11_app.dart';

/// Test suite edukatif untuk analisis mendalam RepaintBoundary pada Modul 11.
///
/// Materi Edukasi dan Temuan Arsitektur:
/// 1. ListView secara default membungkus kontennya ke dalam RenderViewport.
///    RenderViewport secara internal mengimplementasikan isRepaintBoundary = true.
///    Artinya, batas repaint (repaint boundary) sudah aktif pada level viewport,
///    sehingga proses repainting konten daftar terisolasi dari widget luar
///    (seperti AppBar, SearchField, dan FilterChip).
///
/// 2. Apakah Card atau item individual di dalam ListView memerlukan RepaintBoundary manual?
///    Jawabannya: TIDAK.
///    a. ListView.builder bawaan Flutter sudah memiliki parameter addRepaintBoundaries
///       yang bernilai true secara default pada SliverChildBuilderDelegate.
///    b. Jika pengembang membungkus Card secara manual lagi dengan RepaintBoundary
///       di dalam itemBuilder, tercipta nested RepaintBoundary ganda yang sia-sia.
///    c. Menambahkan RepaintBoundary sembarangan pada setiap item kecil justru menambah
///       alokasi memori layer tree (overhead layer). Setiap RepaintBoundary menciptakan
///       OffsetLayer atau PictureLayer terpisah di GPU compositing tree.
///    d. Untuk item daftar yang sangat sederhana dan statis (hanya teks dan ikon kecil),
///       menonaktifkan addRepaintBoundaries (addRepaintBoundaries: false) bahkan dapat
///       menghemat alokasi layer tree karena seluruh item dapat digambar dalam satu
///       draw call pada layer milik RenderViewport.
///
/// 3. Kapan RepaintBoundary BENAR-BENAR dibutuhkan (Use Case Sah):
///    a. Widget dengan frekuensi repaint sangat tinggi (seperti animasi berulang,
///       CustomPaint dinamis, pemutar video, atau ticker) agar repainting-nya tidak
///       merambat ke widget induk maupun widget tetangga.
///    b. Subtree yang sangat kompleks dan mahal untuk di-render ulang, berada di dekat
///       elemen UI lain yang sering berubah.
void main() {
  group('Analisis Arsitektur RepaintBoundary pada ListView dan Viewport', () {
    testWidgets(
      '1. RenderViewport pada ListView secara default memiliki isRepaintBoundary bernilai true',
      (WidgetTester tester) async {
        await tester.pumpWidget(const Modul11App());
        await tester.pumpAndSettle();

        // Temukan widget Viewport di dalam ListView Modul 11
        final viewportFinder = find.byType(Viewport);
        expect(viewportFinder, findsOneWidget);

        // Ambil RenderViewport dari elemen widget yang ditemukan
        final RenderViewport renderViewport =
            tester.renderObject<RenderViewport>(viewportFinder);

        // Bukti teknis: Viewport adalah RepaintBoundary bawaan Flutter
        expect(
          renderViewport.isRepaintBoundary,
          isTrue,
          reason:
              'RenderViewport wajib bertindak sebagai RepaintBoundary untuk '
              'mengisolasi repainting konten gulir dari UI luar.',
        );

        // Verifikasi bahwa viewport memiliki ukuran valid dan offset scrollable
        expect(renderViewport.hasSize, isTrue);
        expect(renderViewport.offset, isNotNull);
      },
    );

    testWidgets(
      '2. Item Card pada Modul 11 tidak dibungkus RepaintBoundary manual redundan',
      (WidgetTester tester) async {
        await tester.pumpWidget(const Modul11App());
        await tester.pumpAndSettle();

        // Ambil semua Card yang aktif di viewport
        final cardFinders = find.byType(Card);
        expect(cardFinders, findsWidgets);

        // Verifikasi bahwa di dalam Card tidak disisipkan RepaintBoundary berlebih
        final firstCard = cardFinders.first;
        final repaintBoundariesInCard = find.descendant(
          of: firstCard,
          matching: find.byType(RepaintBoundary),
        );

        expect(
          repaintBoundariesInCard,
          findsNothing,
          reason:
              'Item Card statis tidak boleh dibungkus RepaintBoundary manual di dalamnya. '
              'Menyematkan RepaintBoundary manual pada setiap Card menambah alokasi layer tree.',
        );

        // Pastikan render object dari Card bukan RepaintBoundary mandiri
        final RenderBox cardBox = tester.renderObject<RenderBox>(firstCard);
        expect(
          cardBox.isRepaintBoundary,
          isFalse,
          reason:
              'RenderObject milik Card tidak menjadi repaint boundary mandiri, '
              'sehingga digambar secara efisien dalam layer bawaan list.',
        );
      },
    );
  });

  group('Eksperimen Komparasi Layer Tree dan Analisis Overhead Alokasi Layer',
      () {
    Widget buildCustomListView({
      required bool addRepaintBoundariesDelegate,
      required bool manualWrapItemWithRepaintBoundary,
      required int itemCount,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            addRepaintBoundaries: addRepaintBoundariesDelegate,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final card = Card(
                key: ValueKey('test-card-$index'),
                child: ListTile(
                  leading: const Icon(Icons.assignment_outlined),
                  title: Text('Tugas Ke-$index'),
                  subtitle: const Text('Mata Kuliah Performa'),
                ),
              );

              if (manualWrapItemWithRepaintBoundary) {
                return RepaintBoundary(
                  key: ValueKey('manual-boundary-$index'),
                  child: card,
                );
              }
              return card;
            },
          ),
        ),
      );
    }

    testWidgets(
      '3. Komparasi alokasi RepaintBoundary membuktikan bahaya nested boundary dan overhead layer',
      (WidgetTester tester) async {
        const int totalItems = 20;

        // SKENARIO A: addRepaintBoundaries = false, tanpa pembungkus manual.
        // Hasil: 0 RepaintBoundary di level item. Seluruh item digambar pada single layer canvas Viewport.
        await tester.pumpWidget(
          buildCustomListView(
            addRepaintBoundariesDelegate: false,
            manualWrapItemWithRepaintBoundary: false,
            itemCount: totalItems,
          ),
        );
        final int countSkenarioA = find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(RepaintBoundary),
            )
            .evaluate()
            .length;
        expect(
          countSkenarioA,
          equals(0),
          reason:
              'Saat addRepaintBoundaries=false dan tanpa pembungkus manual, '
              'tidak ada alokasi RepaintBoundary di dalam ListView.',
        );

        // SKENARIO B: addRepaintBoundaries = true (bawaan ListView), tanpa pembungkus manual.
        // Hasil: Setiap item yang aktif di viewport dibungkus tepat 1 RepaintBoundary oleh delegate.
        await tester.pumpWidget(
          buildCustomListView(
            addRepaintBoundariesDelegate: true,
            manualWrapItemWithRepaintBoundary: false,
            itemCount: totalItems,
          ),
        );
        await tester.pumpAndSettle();

        final int countCardsDiViewport = find.byType(Card).evaluate().length;
        final int countSkenarioB = find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(RepaintBoundary),
            )
            .evaluate()
            .length;
        expect(
          countSkenarioB,
          equals(countCardsDiViewport),
          reason:
              'ListView dengan addRepaintBoundaries=true membungkus setiap sliver '
              'dengan tepat 1 RepaintBoundary otomatis.',
        );

        // SKENARIO C: Anti-pattern: addRepaintBoundaries = true DAN dibungkus manual lagi di itemBuilder.
        // Hasil: Terjadi pemborosan layer ganda (nested RepaintBoundary).
        await tester.pumpWidget(
          buildCustomListView(
            addRepaintBoundariesDelegate: true,
            manualWrapItemWithRepaintBoundary: true,
            itemCount: totalItems,
          ),
        );
        await tester.pumpAndSettle();

        final int countSkenarioC = find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(RepaintBoundary),
            )
            .evaluate()
            .length;
        expect(
          countSkenarioC,
          equals(countCardsDiViewport * 2),
          reason:
              'Membungkus RepaintBoundary secara manual di itemBuilder saat delegate '
              'sudah aktif menggandakan jumlah layer tree menjadi 2x lipat (nested boundary).',
        );

        // Verifikasi bahwa seluruh node RenderRepaintBoundary pada skenario C terdaftar di render tree
        final renderBoundaries = tester.renderObjectList<RenderRepaintBoundary>(
          find.descendant(
            of: find.byType(ListView),
            matching: find.byType(RepaintBoundary),
          ),
        );
        expect(renderBoundaries.length, equals(countSkenarioC));
        for (final rb in renderBoundaries) {
          expect(rb.isRepaintBoundary, isTrue);
        }
      },
    );

    testWidgets(
      '4. RepaintBoundary efektif mengisolasi widget dengan perubahan berkala dari widget statis',
      (WidgetTester tester) async {
        // Pembuktian use case sah:
        // Widget dengan update berkala dibungkus RepaintBoundary agar repaint tidak
        // merambat ke widget tetangga yang statis.
        int buildCountDinamis = 0;
        int buildCountStatis = 0;

        final ValueNotifier<int> counterNotifier = ValueNotifier<int>(0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  RepaintBoundary(
                    key: const ValueKey('isolated-ticker'),
                    child: ValueListenableBuilder<int>(
                      valueListenable: counterNotifier,
                      builder: (context, count, child) {
                        buildCountDinamis++;
                        return Text('Hitungan: $count');
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      buildCountStatis++;
                      return const Text('Widget Statis Pendamping');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final initialStatic = buildCountStatis;
        final initialDynamic = buildCountDinamis;

        // Picu pembaruan pada widget dinamis
        counterNotifier.value = counterNotifier.value + 1;
        await tester.pump();

        // Widget dinamis ter-update
        expect(buildCountDinamis, greaterThan(initialDynamic));
        // Widget statis pendamping tetap tidak terpengaruh
        expect(buildCountStatis, equals(initialStatic));
      },
    );

    testWidgets(
      '5. Stabilitas RenderViewport Modul 11 App saat interaksi filter dan pencarian aktif',
      (WidgetTester tester) async {
        await tester.pumpWidget(const Modul11App());
        await tester.pumpAndSettle();

        // Verifikasi awal RenderViewport
        final viewportFinder = find.byType(Viewport);
        RenderViewport viewport =
            tester.renderObject<RenderViewport>(viewportFinder);
        expect(viewport.isRepaintBoundary, isTrue);

        // Interaksi filter status: Selesai
        final chipSelesai = find.widgetWithText(FilterChip, 'Selesai');
        await tester.tap(chipSelesai);
        await tester.pumpAndSettle();

        // Pastikan boundary viewport tetap utuh
        viewport = tester.renderObject<RenderViewport>(viewportFinder);
        expect(viewport.isRepaintBoundary, isTrue);
        expect(find.text('Menampilkan 250 dari 1000 tugas'), findsOneWidget);

        // Interaksi pencarian teks
        final searchField = find.byKey(const ValueKey('task-search'));
        await tester.enterText(searchField, '0004');
        await tester.pumpAndSettle();

        // Hasil pencarian tersaring dan boundary tetap konsisten
        expect(find.text('Menampilkan 1 dari 1000 tugas'), findsOneWidget);
        viewport = tester.renderObject<RenderViewport>(viewportFinder);
        expect(viewport.isRepaintBoundary, isTrue);
      },
    );
  });
}
