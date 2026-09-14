import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poliwangi_mobile_starter/modul_04/models/announcement.dart';
import 'package:poliwangi_mobile_starter/modul_04/repositories/announcement_repository.dart';
import 'package:poliwangi_mobile_starter/modul_04/repositories/sample_announcement_repository.dart';
import 'package:poliwangi_mobile_starter/modul_04/providers/announcement_provider.dart';
import 'package:poliwangi_mobile_starter/modul_04/screens/announcement_list_screen.dart';

// Mock Repository untuk pengujian widget terisolasi
class FakeAnnouncementRepository implements AnnouncementRepository {
  final List<Announcement> _mockData;
  final bool shouldFail;

  FakeAnnouncementRepository({
    List<Announcement>? mockData,
    this.shouldFail = false,
  }) : _mockData = mockData ?? Announcement.getSampleAnnouncements();

  @override
  Future<List<Announcement>> getAnnouncements({String? category}) async {
    if (shouldFail) {
      throw Exception('Gagal terhubung ke server');
    }
    if (category == null || category == 'Semua') {
      return _mockData;
    }
    return _mockData
        .where((a) => a.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  @override
  Future<Announcement> addAnnouncement(Announcement announcement) async {
    return announcement;
  }
}

void main() {
  group('Modul 04: Networking & REST API (Dio + Repository + 4-State)', () {
    test(
        '1. Model Announcement mem-parsing payload JSON dan serialisasi toJson dengan benar',
        () {
      final jsonPayload = {
        'id': 101,
        'title': 'Uji Coba Pengumuman',
        'content': 'Ini adalah isi pengumuman uji coba.',
        'author': 'Dosen Penguji',
        'category': 'Akademik',
        'date': '2026-09-03',
        'readCount': 42,
      };

      final announcement = Announcement.fromJson(jsonPayload);
      expect(announcement.id, equals(101));
      expect(announcement.title, equals('Uji Coba Pengumuman'));
      expect(announcement.author, equals('Dosen Penguji'));
      expect(announcement.category, equals('Akademik'));
      expect(announcement.readCount, equals(42));

      final serialized = announcement.toJson();
      expect(serialized['id'], equals(101));
      expect(serialized['title'], equals('Uji Coba Pengumuman'));
    });

    test('2. Repository menyaring pengumuman berdasarkan kategori yang dipilih',
        () async {
      final repo = FakeAnnouncementRepository();

      final all = await repo.getAnnouncements(category: 'Semua');
      expect(all.length, greaterThanOrEqualTo(4));

      final akademik = await repo.getAnnouncements(category: 'Akademik');
      expect(akademik.every((a) => a.category == 'Akademik'), isTrue);
    });

    test('3. Repository data sampel mendukung demo offline dan filter kategori',
        () async {
      final repo = SampleAnnouncementRepository();

      final all = await repo.getAnnouncements();
      final beasiswa = await repo.getAnnouncements(category: 'Beasiswa');
      expect(all, isNotEmpty);
      expect(beasiswa, isNotEmpty);
      expect(beasiswa.every((item) => item.category == 'Beasiswa'), isTrue);
    });

    testWidgets(
        '4. AnnouncementListScreen menampilkan AppBar, filter chips, dan daftar data sukses',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            announcementRepositoryProvider
                .overrideWithValue(FakeAnnouncementRepository()),
          ],
          child: const MaterialApp(
            home: AnnouncementListScreen(),
          ),
        ),
      );

      // Tunggu hingga FutureProvider selesai memuat data
      await tester.pumpAndSettle();

      // Verifikasi judul AppBar
      expect(find.text('Portal Pengumuman TRPL'), findsOneWidget);

      // Verifikasi filter kategori dirender sebagai ChoiceChip. Label kategori
      // juga dapat muncul pada kartu, sehingga jumlah widget Text bukan acuan.
      expect(find.byType(ChoiceChip), findsNWidgets(5));

      // Verifikasi Card pengumuman ter-render
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets(
        '5. AnnouncementListScreen menampilkan Error State dan tombol Coba Lagi saat request gagal',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            announcementRepositoryProvider.overrideWithValue(
              FakeAnnouncementRepository(shouldFail: true),
            ),
          ],
          child: const MaterialApp(
            home: AnnouncementListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifikasi pesan error dan tombol Coba Lagi
      expect(find.text('Gagal Memuat Data'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });
  });
}
