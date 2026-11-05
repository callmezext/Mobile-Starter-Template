# Komparasi Arsitektural: Lazy Building (ListView.builder) vs Data Pagination

Dokumen ini membedah perbedaan mendasar antara mekanisme **Lazy Building** pada lapisan antarmuka (UI Rendering Layer) menggunakan `ListView.builder` dan strategi **Data Pagination** pada lapisan pengambilan data (Data Retrieval Layer). Pemahaman yang keliru terhadap kedua konsep ini sering menjadi akar masalah kebocoran memori (*memory leak*), konsumsi bandwidth berlebih, hingga aplikasi berhenti mendadak akibat *Out of Memory* (OOM) pada perangkat seluler.

---

## 1. Mengapa ListView.builder Bukan Pagination Data

Kerap ditemukan miskonsepsi di kalangan pengembang Flutter bahwa membungkus daftar item dengan `ListView.builder` secara otomatis telah menerapkan "pagination". Anggapan ini keliru secara arsitektural karena mencampuradukkan dua lapisan komputasi yang independen.

```
+-----------------------------------------------------------------------+
|                        ARSITEKTUR APLIKASI                            |
+-----------------------------------------------------------------------+
| 1. DATA RETRIEVAL LAYER (Remote API, Database SQLite, Network)        |
|    - Tanggung Jawab: Mengambil dan memuat dataset dari sumber data.   |
|    - Mekanisme Optimasi: Data Pagination (Offset / Cursor-based).     |
+-----------------------------------------------------------------------+
                                  |
                                  v
+-----------------------------------------------------------------------+
| 2. STATE / IN-MEMORY STORAGE LAYER (Dart VM Heap RAM)                 |
|    - Tanggung Jawab: Menyimpan struktur data aktif (List<T>).         |
|    - Karakteristik: Seluruh item yang di-fetch mendiami RAM perangkat.|
+-----------------------------------------------------------------------+
                                  |
                                  v
+-----------------------------------------------------------------------+
| 3. UI RENDERING LAYER (Flutter Framework & Render Pipeline)           |
|    - Tanggung Jawab: Mengkalkulasi geometri, layout, dan melukis piksel|
|    - Mekanisme Optimasi: Lazy Building (ListView.builder, Slivers).   |
+-----------------------------------------------------------------------+
```

### Pemisahan Tanggung Jawab (Separation of Concerns)

1. **UI Rendering Layer (`ListView.builder`)**:
   - Beroperasi secara lokal di sisi rendering engine Flutter.
   - Mengontrol siklus hidup instansiasi `Widget`, `Element`, dan `RenderObject`.
   - Mengoptimalkan alokasi grafis dan kalkulasi layout: Flutter hanya membuat node visual untuk item yang sedang tampak di dalam jendela pandang (*viewport*) ditambah sedikit area penyangga (*cacheExtent*).
   - **Batas Kemampuan**: `ListView.builder` tidak memiliki kendali terhadap bagaimana data diambil, berapa banyak objek yang dimuat ke memori Dart VM, atau berapa megabita data mentah yang diunduh dari jaringan.

2. **Data Retrieval Layer (Data Pagination)**:
   - Beroperasi pada integrasi data (REST API, GraphQL, gRPC, atau query database lokal seperti SQLite/Isar).
   - Mengontrol transfer data mentah dari penyedia data (*data provider*) ke memori kerja aplikasi (*in-memory storage*).
   - Mengambil data dalam potongan-potongan terukur (*chunks* atau halaman), misalnya 20 atau 50 entitas per permintaan, alih-alih mengunduh 50.000 entitas sekaligus.

Jika sebuah aplikasi mengunduh 20.000 objek data dari backend dalam satu HTTP call dan menyimpannya dalam `List<Model>`, lalu menyajikannya dengan `ListView.builder`, aplikasi tersebut **hanya melakukan optimasi rendering, bukan optimasi data**. Beban memori Dart heap, beban deserialisasi JSON, dan latensi jaringan awal tetap terjadi secara penuh.

---

## 2. Cara Kerja ListView.builder di Memori (Dart VM Heap vs Render Tree)

Untuk memahami perilaku memori `ListView.builder`, mari bedah kasus nyata yang diterapkan pada Modul 11 (`lib/module_11/modul_11_app.dart`), di mana terdapat 1.000 objek `TugasPerforma` yang dihasilkan dalam list `_semuaTugas`.

### Alokasi Memori Dart VM Heap

Pada saat list dibuat:
```dart
final List<TugasPerforma> _semuaTugas = List<TugasPerforma>.generate(
  1000,
  (index) => TugasPerforma(
    nomor: index + 1,
    mataKuliah: daftarMataKuliah[index % 8],
    status: (index + 1) % 4 == 0 ? StatusTugas.selesai : StatusTugas.aktif,
  ),
);
```
- **1.000 Objek Model Hidup di Dart VM Heap**:
  Seluruh 1.000 instansi `TugasPerforma` mendiami alokasi memori Dart heap secara penuh. Setiap instansi objek memiliki overhead memori berupa *object header*, pointer referensi tipe data, serta nilai field string (`nomor`, `mataKuliah`, `status`).
- Objek-objek ini tetap berada di RAM selama state layar aktif, terlepas dari apakah item tersebut pernah digulir (*scrolled*) atau tidak.

### Alokasi RenderObject di Render Tree

Ketika list tersebut dirender menggunakan:
```dart
ListView.builder(
  itemCount: hasil.length,
  itemBuilder: (context, index) => _KartuTugas(tugas: hasil[index]),
)
```
Flutter mendelegasikan tugas layout kepada `RenderSliverList`. Mekanismenya adalah:

1. **Viewport & Cache Extent**:
   Tinggi layar perangkat ponsel umumnya berada di rentang 600 sampai 900 logical pixels. Jika tinggi satu baris kartu tugas adalah 80 logical pixels, maka viewport hanya mampu menampung sekitar 8 sampai 10 kartu dalam satu waktu.
2. **Kalkulasi Lazy Instantiation**:
   `ListView.builder` memanfaatkan `SliverChildBuilderDelegate`. Flutter hanya memanggil callback `itemBuilder` untuk indeks yang posisinya bersinggungan dengan area viewport ditambah `cacheExtent` (area penyangga di atas dan di bawah viewport, default 250 logical pixels).
3. **Jumlah Node yang Aktif**:
   Meskipun terdapat 1.000 item di dalam `List`, hanya sekitar 10 sampai 15 widget `_KartuTugas`, 10 sampai 15 `Element`, dan 10 sampai 15 node `RenderObject` yang eksis di dalam memori visual pada satu waktu.
4. **Siklus Recycling dan Pembuangan (Garbage Collection)**:
   Ketika pengguna menggulir layar ke bawah:
   - Kartu bagian atas yang meninggalkan viewport dan keluar dari batas `cacheExtent` akan dinonaktifkan (*unmounted*). `Element` dan `RenderObject` kartu tersebut dibuang dari tree (*deallocated*).
   - Kartu baru yang mulai memasuki batas `cacheExtent` dari bawah dipanggilkan `itemBuilder(context, nextIndex)` untuk dibangun secara instan.
   - Objek model di `_semuaTugas` tetap utuh di memori Dart, namun representasi visualnya dinamis dibuat dan dibuang.

### Diagram Alur: Dart VM Heap vs Render Tree

```
+-----------------------------------------------------------------------+
| DART VM HEAP MEMORY (Data Model Storage)                              |
| Status: Semua 1.000 model tugas menetap di RAM                       |
+-----------------------------------------------------------------------+
  [Tugas #1] [Tugas #2] [Tugas #3] ... [Tugas #12] ... [Tugas #1000]
      |          |          |              |                 |
      | (Diikat oleh itemBuilder hanya saat masuk viewport)  |
      v          v          v              v                 x (Tidak dibuat)
+-----------------------------------------------------------------------+
| FLUTTER RENDER TREE (Visual Layout & Painting)                        |
| Status: Hanya ~10-15 RenderObject aktif sekaligus                     |
+-----------------------------------------------------------------------+
  [Card 1]   [Card 2]   [Card 3]  ...  [Card 12]        (Index > 15:
  RenderBox  RenderBox  RenderBox      RenderBox         TIDAK DIEKSEKUSI)
+-----------------------------------------------------------------------+
| VIEWPORT LAYAR PONSEL (Tinggi 800px)                                  |
| Area yang tampak di mata pengguna (Visual Active Area)                |
+-----------------------------------------------------------------------+
```

---

## 3. Kapan Data Pagination Mutlak Diperlukan

Walaupun `ListView.builder` sangat efisien menghemat konsumsi GPU dan Render Tree, `ListView.builder` tidak mampu menyelesaikan masalah apabila dataset berskala masif atau berasal dari jaringan eksternal.

Berikut adalah kondisi di mana arsitektur **Data Pagination** mutlak diwajibkan:

### 1. Dataset Skala Besar (> 10.000 Item)
Jika koleksi data mencapai puluhan ribu atau ratusan ribu entitas:
- **Konsumsi RAM Dart VM**: Mempertahankan 50.000 model objek bertipe kompleks di dalam memori Dart dapat menghabiskan puluhan hingga ratusan megabita RAM. Pada perangkat Android berspesifikasi rendah (*low-end devices*), kondisi ini memicu *Low Memory Killer* (LMK) sistem operasi yang mematikan aplikasi secara paksa (*crash OOM*).
- **Garbage Collection Pressure**: Ketika list besar tersebut dimodifikasi, disaring (*filtering*), atau diurutkan (*sorting*), Dart VM Garbage Collector terpaksa melakukan siklus sweep pada heap yang padat, menyebabkan *GC pauses* (hentakan mikro) yang mencuri jatah frame 16.6ms (60 FPS) atau 8.3ms (120 FPS).

### 2. Pengambilan Data via REST API, GraphQL, atau Jaringan
Mengambil seluruh dataset sekaligus (*eager fetching*) melalui jaringan menimbulkan berbagai kerugian:
- **Time to First Byte (TTFB) dan Latensi Awal**: Server memerlukan waktu lama untuk menjalankan query database, men-serialize puluhan ribu baris ke payload JSON, dan mengirimkannya via TCP/IP. Pengguna disajikan indikator loading berputar (*spinner*) selama beberapa detik hingga menit.
- **Pemborosan Kuota Bandwidth**: Pengguna rata-rata hanya melihat 10 sampai 20 item teratas. Mengunduh sisa 9.980 item yang tidak pernah dilihat pengguna adalah pemborosan kuota internet pengguna dan pemborosan bandwidth server penyedia.
- **Beban CPU saat Parsing JSON**: Melakukan parsing string JSON berukuran puluhan megabita secara sinkron di UI thread akan membekukan aplikasi (*ANR / Application Not Responding*). Sekalipun dipindahkan ke background isolate (`compute`), alokasi memori untuk struktur map mentah dan model tetap sangat besar.

### 3. Query Database Lokal (SQLite, Isar, Drift, Room)
Membaca seluruh isi tabel yang berisi 100.000 baris ke dalam memori RAM sekaligus akan memblokir thread I/O database dan membebani alokasi memori proses lokal. Query harus menerapkan klausa `LIMIT` dan `OFFSET` atau pemindaian berbasis indeks (*indexed keyset*).

### Strategi Pagination: Offset-Based vs Cursor-Based

| Parameter | Offset-Based Pagination | Cursor-Based / Keyset Pagination |
| :--- | :--- | :--- |
| **Konsep Kunci** | Menggunakan nomor halaman (`page=3&limit=20`) atau `OFFSET 40 LIMIT 20`. | Menggunakan penanda posisi item terakhir (`after_id=12854&limit=20`). |
| **Karakteristik Skalabilitas** | Menurun seiring bertambahnya nilai offset. Database harus memindai dan membuang N baris pertama sebelum mengambil data. | Sangat cepat dan konstan (O(log N)) karena langsung memanfaatkan B-Tree index pada kolom cursor. |
| **Konsistensi Data** | Rentan terhadap pergeseran data (*duplicate items* atau *skipped items*) jika ada penyisipan data baru saat pengguna sedang scrolling. | Stabil dan kebal terhadap pergeseran data karena posisi penanda terikat secara unik pada record terakhir. |
| **Kasus Penggunaan Ideal** | Dataset kecil hingga menengah dengan navigasi nomor halaman langsung (halaman 1, 2, 5). | Infinite scroll pada linimasa sosial, log aktivitas, katalog produk berukuran besar, dan dataset real-time. |

---

## 4. Tabel Komparasi Komprehensif

| Dimensi Arsitektural | ListView.builder (Lazy Rendering) | Data Pagination (Chunked Retrieval) |
| :--- | :--- | :--- |
| **Lapisan Fokus (Layer Scope)** | **UI Rendering Layer** (Framework Flutter, Element Tree, RenderObject Tree). | **Data Retrieval Layer** (REST API, Database Engine, Remote Service). |
| **Tujuan Utama** | Mencegah pembengkakan pohon visual dan membatasi kalkulasi layout/paint hanya pada area tampak. | Mencegah transfer data berlebih melalui jaringan dan membatasi alokasi RAM pada Dart VM. |
| **Kebutuhan Data di Memori** | Seluruh dataset yang dipasok ke `itemCount` harus sudah berada di RAM Dart VM. | Data di RAM bertambah secara bertahap sesuai kebutuhan penelusuran pengguna (*chunk by chunk*). |
| **Konsumsi Memori Dart Heap** | **Tinggi jika dataset besar**: 10.000 objek data model tetap menghuni RAM penuh. | **Terkendali**: Hanya memuat sejumlah halaman aktif (misal 40-100 model data pada satu waktu). |
| **Konsumsi RenderObject & GPU** | **Sangat Rendah dan Konstan**: Hanya ~10-15 RenderObject yang aktif dialokasikan di viewport. | Tidak mengatur layout visual secara langsung. Bekerja optimal bila digabungkan dengan `ListView.builder`. |
| **Penggunaan Bandwidth Jaringan** | Nol pengaruh: Tidak menangani komunikasi jaringan sama sekali. | **Sangat Hemat**: Mengunduh payload bertahap (misal 20 record per batch) saat pengguna mendekati batas bawah. |
| **Beban Server dan Database** | Tidak berhubungan dengan server. Beban sepenuhnya di sisi client engine. | Meringankan beban query server melalui pembagian beban pemrosesan (*chunked queries*). |
| **Skalabilitas Dataset (> 100.000 Item)** | **Gagal/OOM**: Aplikasi kehabisan memori RAM saat mencoba memuat 100.000 model ke memori sebelum list dirender. | **Sangat Baik**: Mampu menangani jutaan baris data secara mulus tanpa lonjakan memori. |
| **Kompleksitas Implementasi** | Sederhana: Menggunakan konstruktor standar Flutter bawaan tanpa dependensi luar. | Menengah: Memerlukan penanganan scroll listener, status loading berikutnya, penanganan error batch, dan deduplikasi data. |

---

## 5. Pola Sinergi: Menggabungkan Pagination dan Lazy Building

Arsitektur aplikasi mobile modern yang tangguh tidak memilih salah satu di antara keduanya, melainkan **mensinergikan keduanya** dalam arsitektur berlapis:

```
+-----------------------------------------------------------------------------------+
| 1. LAPISAN DATA (Pagination)                                                      |
|    - Infinite Scroll memantau posisi scroll pengguna.                             |
|    - Saat sisa jarak scroll < 300px, panggil fetchNextPage() (ambil 20 item).     |
|    - Server merespons dengan payload JSON mini (20 entitas).                      |
|    - 20 entitas ditambahkan ke koleksi lokal State.                               |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| 2. LAPISAN TAMPILAN (Lazy Building)                                               |
|    - ListView.builder menerima koleksi data yang bertambah tersebut.              |
|    - Hanya ~10-15 item di viewport yang diinstansiasi menjadi RenderObject.       |
|    - Tampilkan CircularProgressIndicator di index terakhir saat batch baru dimuat.|
+-----------------------------------------------------------------------------------+
```

### Pola Implementasi Sederhana pada Flutter

```dart
class DaftarItemTeroptimasi extends StatefulWidget {
  const DaftarItemTeroptimasi({super.key});

  @override
  State<DaftarItemTeroptimasi> createState() => _DaftarItemTeroptimasiState();
}

class _DaftarItemTeroptimasiState extends State<DaftarItemTeroptimasi> {
  final ScrollController _scrollController = ScrollController();
  final List<ItemData> _items = [];
  bool _sedangMemuat = false;
  bool _adaHalamanBerikutnya = true;
  int _halamanSaatIni = 1;

  @override
  void initState() {
    super.initState();
    _ambilHalamanBerikutnya();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Pemicu pagination: saat pengguna mencapai 80% dari batas gulir maksimum
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_sedangMemuat &&
        _adaHalamanBerikutnya) {
      _ambilHalamanBerikutnya();
    }
  }

  Future<void> _ambilHalamanBerikutnya() async {
    setState(() => _sedangMemuat = true);

    try {
      final itemBaru = await RepositoryLayanan.ambilData(halaman: _halamanSaatIni);
      setState(() {
        _items.addAll(itemBaru);
        _halamanSaatIni++;
        _adaHalamanBerikutnya = itemBaru.isNotEmpty;
        _sedangMemuat = false;
      });
    } catch (e) {
      setState(() => _sedangMemuat = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      // Tambahkan 1 slot ekstra untuk indikator loading jika masih ada halaman berikutnya
      itemCount: _items.length + (_adaHalamanBerikutnya ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        return KartuItem(item: _items[index]);
      },
    );
  }
}
```

---

## 6. Kesimpulan Arsitektural

1. **ListView.builder bukan pagination**: `ListView.builder` adalah mekanisme *lazy evaluation* visual di UI thread, bukan pengatur ukuran transfer data.
2. **Keterbatasan RAM**: 1.000 objek model pada Modul 11 aman dikelola di RAM Dart heap karena ukuran payload kecil dan lokal. Namun jika dataset berkembang menjadi puluhan ribu item atau berasal dari jaringan, pagination pada Data Retrieval Layer menjadi keharusan mutlak.
3. **Standar Emas Arsitektur**:
   - Gunakan **Data Pagination (Cursor-based)** pada Data Layer untuk menjaga kuota bandwidth dan mencegah *Out of Memory* pada Dart VM Heap.
   - Gunakan **Lazy Building (`ListView.builder`)** pada UI Layer untuk menjaga frame rate 60/120 FPS dan membatasi konsumsi memori Render Tree di GPU/Skia/Impeller.
