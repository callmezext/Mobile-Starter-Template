import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poliwangi_mobile_starter/module_11/modul_11_app.dart';

/// Komponen representasi Eager List: ListView(children: ...)
/// Seluruh 1.000 item kartu langsung di-instansiasi ke dalam memori saat build pertama.
class EagerTaskListView extends StatelessWidget {
  const EagerTaskListView({
    super.key,
    required this.tasks,
    required this.onCardInstantiated,
  });

  final List<TugasPerforma> tasks;
  final void Function(int index) onCardInstantiated;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('eager-task-list'),
      children: tasks.asMap().entries.map((entry) {
        onCardInstantiated(entry.key);
        final tugas = entry.value;
        return Card(
          key: ValueKey('eager-task-card-${tugas.nomor}'),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.assignment_outlined)),
            title: Text(tugas.judul),
            subtitle: Text(tugas.mataKuliah),
          ),
        );
      }).toList(),
    );
  }
}

/// Komponen representasi Lazy List: ListView.builder(...)
/// Hanya item yang masuk ke dalam viewport dan buffer cache yang di-instansiasi.
class LazyTaskListView extends StatelessWidget {
  const LazyTaskListView({
    super.key,
    required this.tasks,
    required this.onCardInstantiated,
  });

  final List<TugasPerforma> tasks;
  final void Function(int index) onCardInstantiated;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const ValueKey('lazy-task-list'),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        onCardInstantiated(index);
        final tugas = tasks[index];
        return Card(
          key: ValueKey('lazy-task-card-${tugas.nomor}'),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.assignment_outlined)),
            title: Text(tugas.judul),
            subtitle: Text(tugas.mataKuliah),
          ),
        );
      },
    );
  }
}

void main() {
  group('Fase B Pengayaan: Uji Komparasi Performa Eager vs Lazy List', () {
    late List<TugasPerforma> dummyTasks;

    setUp(() {
      dummyTasks = List<TugasPerforma>.generate(
        1000,
        (index) => TugasPerforma(
          nomor: index + 1,
          mataKuliah: 'Pemrograman Mobile',
          status: (index + 1) % 4 == 0 ? StatusTugas.selesai : StatusTugas.aktif,
        ),
      );
    });

    testWidgets(
      '1. Perbandingan instansiasi Card awal: Eager (1000) vs Lazy (~10-15) dengan penghematan >95%',
      (WidgetTester tester) async {
        int eagerCardCount = 0;
        int lazyCardCount = 0;

        // Uji Skenario A: Eager loading menggunakan ListView(children: ...)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EagerTaskListView(
                tasks: dummyTasks,
                onCardInstantiated: (_) => eagerCardCount++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Pada eager list, seluruh 1.000 Card langsung di-instansiasi ke memori
        expect(
          eagerCardCount,
          equals(1000),
          reason: 'ListView(children: ...) harus meng-instansiasi seluruh 1.000 Card sekaligus.',
        );

        // Uji Skenario B: Lazy loading menggunakan ListView.builder(...)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LazyTaskListView(
                tasks: dummyTasks,
                onCardInstantiated: (_) => lazyCardCount++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Pada builder list, hanya kartu yang masuk viewport (~10-15 kartu) yang di-instansiasi
        expect(
          lazyCardCount,
          greaterThanOrEqualTo(10),
          reason: 'ListView.builder harus meng-instansiasi setidaknya 10 kartu untuk viewport awal.',
        );
        expect(
          lazyCardCount,
          lessThanOrEqualTo(20),
          reason: 'ListView.builder tidak boleh meng-instansiasi lebih dari 20 kartu pada viewport awal.',
        );

        // Hitung persentase penghematan instansiasi widget Card
        final savingsPercentage =
            ((eagerCardCount - lazyCardCount) / eagerCardCount) * 100.0;

        // Buktikan secara konkret melalui test assertion bahwa penghematan >95%
        expect(
          savingsPercentage,
          greaterThan(95.0),
          reason:
              'ListView.builder wajib menghemat pembuatan widget Card >95% pada initial frame (tercapai: ${savingsPercentage.toStringAsFixed(2)}%).',
        );

        // Verifikasi rasio perbandingan konkret (1.000 banding ~14 kartu)
        expect(
          eagerCardCount,
          greaterThan(lazyCardCount * 50),
          reason: 'Instansiasi eager harus lebih dari 50 kali lipat lebih banyak dibanding lazy.',
        );
      },
    );

    testWidgets(
      '2. Verifikasi jumlah Card yang aktif di widget tree pada Modul11App membuktikan efisiensi lazy rendering',
      (WidgetTester tester) async {
        await tester.pumpWidget(const Modul11App());
        await tester.pumpAndSettle();

        // Verifikasi jumlah Card di element tree hanya yang berada di area pandang layar
        final activeCardsCount = find.byType(Card).evaluate().length;

        expect(activeCardsCount, greaterThan(0));
        expect(activeCardsCount, lessThan(20));

        // Efisiensi widget tree: penghematan elemen aktif dibanding total data 1.000 item
        final elementTreeSaving = ((1000 - activeCardsCount) / 1000.0) * 100.0;
        expect(
          elementTreeSaving,
          greaterThan(98.0),
          reason: 'Alokasi Card di element tree harus hemat >98% dari total 1.000 tugas.',
        );
      },
    );

    testWidgets(
      '3. ListView.builder meng-instansiasi kartu baru secara bertahap (on-demand) saat di-scroll',
      (WidgetTester tester) async {
        final instantiatedIndices = <int>{};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LazyTaskListView(
                tasks: dummyTasks,
                onCardInstantiated: (index) => instantiatedIndices.add(index),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final initialCount = instantiatedIndices.length;
        expect(initialCount, inInclusiveRange(10, 20));

        // Indeks kartu yang dibuat di awal hanya berkisar di awal list (0 sampai initialCount - 1)
        expect(instantiatedIndices.contains(0), isTrue);
        expect(instantiatedIndices.contains(999), isFalse);

        // Scroll daftar ke bawah sejauh 500 pixel untuk memicu instansiasi item baru
        await tester.drag(find.byKey(const ValueKey('lazy-task-list')), const Offset(0, -500));
        await tester.pumpAndSettle();

        // Jumlah item yang pernah di-instansiasi bertambah karena ada item baru yang masuk viewport
        final countAfterScroll = instantiatedIndices.length;
        expect(
          countAfterScroll,
          greaterThan(initialCount),
          reason: 'Scroll harus memicu instansiasi kartu tambahan secara on-demand.',
        );

        // Kartu terakhir (indeks 999) tetap belum di-instansiasi karena belum digulir hingga akhir
        expect(instantiatedIndices.contains(999), isFalse);
      },
    );
  });
}
