# Panduan Praktikum Profiling Flutter DevTools: Modul 11 (Optimasi Performa)

Dokumen ini merupakan panduan praktikum komprehensif bagi mahasiswa dan pengembang perangkat lunak untuk melakukan *profiling*, analisis performa, dan eliminasi hambatan rendering (*frame jank*) pada aplikasi Flutter menggunakan Flutter DevTools. Panduan ini menggunakan studi kasus nyata Modul 11 (Optimasi Daftar Tugas 1.000 Item) di repositori Flutter Starter Template.

---

## 1. Pendahuluan dan Konsep Dasar Profiling

Profiling adalah proses pengukuran kuantitatif terhadap perilaku eksekusi program pada runtime, meliputi konsumsi CPU, alokasi memori, frekuensi render ulang widget, dan durasi rendering setiap frame visual.

Tujuan utama profiling dalam pengembangan aplikasi Flutter:
1. Menemukan penyebab pasti terjadinya penurunan frame rate atau animasi tersendat (*jank*).
2. Memverifikasi efektivitas teknik optimasi (seperti *lazy loading*, ekstraksi widget, dan *caching repaint*).
3. Memastikan aplikasi mematuhi standar anggaran waktu render (*frame budget*) pada berbagai jenis spesifikasi layar perangkat (60 Hz hingga 120 Hz).
4. Mencegah regresi performa sebelum kode dirilis ke lingkungan produksi.

### Mengapa Profiling Berbasis Bukti Nyata Wajib Dilakukan?
Optimasi tanpa data profiling sering kali menghasilkan *premature optimization*, yaitu menambahkan kompleksitas arsitektur pada bagian kode yang sebenarnya bukan sumber masalah. Dengan Flutter DevTools, keputusan rekayasa perangkat lunak didasarkan pada grafik linimasa (*timeline*), jejak panggilan fungsi (*call tree*), dan metrik alokasi yang dapat dibuktikan.

---

## 2. Menjalankan Aplikasi pada Profile Mode

Flutter menyediakan tiga mode kompilasi: **Debug**, **Profile**, dan **Release**. Pengukuran performa yang sah **hanya** dapat dilakukan pada **Profile Mode**.

### Perbandingan Karakteristik Tiga Mode Build Flutter

| Karakteristik | Debug Mode | Profile Mode | Release Mode |
| :--- | :--- | :--- | :--- |
| **Metode Kompilasi Dart** | JIT (*Just-In-Time*) | AOT (*Ahead-Of-Time*) | AOT (*Ahead-Of-Time*) |
| **Optimasi Kode Kompiler** | Dinonaktifkan (untuk kecepatan reload) | Diaktifkan penuh | Diaktifkan penuh |
| **Pemeriksaan Assert & Safe Cast** | Aktif di seluruh framework | Dinonaktifkan (*stripped*) | Dinonaktifkan (*stripped*) |
| **Hot Reload & Hot Restart** | Aktif | Dinonaktifkan | Dinonaktifkan |
| **Service Extension DevTools** | Aktif lengkap dengan debugger agent | Aktif minimal khusus tracing performa | Dinonaktifkan total |
| **Validitas Analisis Performa** | **TIDAK VALID** (*false positive jank*) | **VALID** (mendekati performa produksi) | Valid (tetapi tanpa instrumentasi) |

### Mengapa Dilarang Melakukan Profiling pada Debug Mode?
1. Kompilasi JIT mengeksekusi *bytecode* perantara yang diterjemahkan secara dinamis, sehingga instruksi CPU membutuhkan siklus jauh lebih banyak dibandingkan instruksi mesin murni hasil AOT.
2. Framework Flutter menjalankan ribuan baris validasi `assert()` pada setiap siklus layout dan paint.
3. Protokol debugging VM Service mengirimkan data inspeksi secara berkala ke workstation, memicu lonjakan waktu eksekusi palsu (*false positive jank*) yang sebenarnya tidak akan dialami pengguna akhir.

### Persyaratan Perangkat Keras
1. **Wajib Menggunakan Perangkat Fisik Nyata**:
   - Selalu gunakan smartphone fisik Android atau iOS yang terhubung melalui kabel USB berkecepatan tinggi atau Wi-Fi adb debugging.
2. **Keterbatasan Simulator dan Emulator**:
   - iOS Simulator pada macOS **tidak mendukung** profile mode karena arsitektur x86_64/arm64 simulator tidak mendukung AOT profiling Flutter.
   - Android Emulator berbagi resource CPU dan kartu grafis dengan sistem operasi host workstation. Lapisan emulasi grafis (*host GPU pass-through*) memperkenalkan latensi yang tidak mencerminkan perangkat keras mobile sesungguhnya.

### Langkah-Langkah Menjalankan Profile Mode via Terminal CLI

1. Hubungkan ponsel pintar fisik Anda ke komputer dan aktifkan mode USB Debugging (Developer Options).
2. Buka terminal atau Command Prompt, lalu arahkan ke root repositori proyek:
   ```bash
   cd <root-folder-proyek>
   ```
3. Periksa daftar perangkat yang terdeteksi dengan perintah:
   ```bash
   flutter devices
   ```
   Pastikan perangkat fisik Anda tercantum beserta identitas perangkatnya (misalnya: `R58M...` atau `emulator-5554`).
4. Jalankan aplikasi pada target Modul 11 dalam profile mode:
   ```bash
   flutter run --profile -d <DEVICE_ID>
   ```
   *Catatan: Jika Anda menjalankan langsung dari launcher utama `lib/main.dart`, pastikan passcode modul dibuka sesuai petunjuk praktikum.*

5. Tunggu proses kompilasi AOT selesai (tahap `Running Gradle task 'assembleProfile'` pada Android). Setelah aplikasi terpasang dan berjalan di ponsel, terminal akan menampilkan pesan URL DevTools dan observatory socket.

---

## 3. Membuka dan Menghubungkan Flutter DevTools

Setelah aplikasi berjalan dalam Profile Mode, Flutter DevTools dapat diakses melalui beberapa metode berikut:

### Metode 1: Menggunakan Tautan Langsung dari Terminal
Di bagian akhir output terminal `flutter run --profile`, Flutter mencetak tautan web interaktif:
```text
An Observatory debugger and profiler on SM-A525F is available at: http://127.0.0.1:54321/xxx/
The Flutter DevTools debugger and profiler on SM-A525F is available at:
http://127.0.0.1:9100?uri=http://127.0.0.1:54321/xxx/
```
Salin tautan `http://127.0.0.1:9100...` tersebut dan buka di peramban web modern berbasis Chromium (seperti Google Chrome atau Microsoft Edge).

### Metode 2: Melalui VS Code (Visual Studio Code)
1. Buka Command Palette dengan menekan kombinasi tombol `Ctrl + Shift + P` (atau `Cmd + Shift + P` di macOS).
2. Ketikkan kata kunci: `Dart: Open DevTools`.
3. Pilih opsi **Open DevTools in Web Browser** untuk area kerja yang luas, atau **Open DevTools in Embedded View** untuk membuka DevTools langsung di dalam tab editor VS Code.

### Metode 3: Melalui Android Studio / IntelliJ IDEA
1. Buka jendela tool window **Flutter Performance** yang terletak di bilah sisi kanan (*tool strip*).
2. Klik ikon tombol bergambar roda gigi biru berlabel **Open DevTools** pada bagian atas toolbar panel.

### Metode 4: Menjalankan DevTools Mandiri (CLI Standalone)
Jika terminal sebelumnya tertutup, jalankan perintah server DevTools secara mandiri:
```bash
dart devtools
```
Buka URL server yang muncul (biasanya `http://127.0.0.1:9100`), lalu masukkan URL koneksi VM Service aplikasi yang sedang aktif pada input field yang tersedia.

---

## 4. Menggunakan Tab Performance (CPU Profiler, Flame Chart, dan Timeline)

Tab **Performance** pada DevTools adalah pusat kendali untuk membedah waktu eksekusi setiap frame dan mengisolasi fungsi komputasi yang berat.

```
+-----------------------------------------------------------------------------------+
|  FLUTTER DEVTOOLS: TAB PERFORMANCE                                                |
+-----------------------------------------------------------------------------------+
|  [Frame Timeline]                                                                 |
|   |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||   |
|   Hijau: Normal (<= 16.6ms)      Oranye/Merah: Jank (> 16.6ms)                    |
+-----------------------------------------------------------------------------------+
|  [Flame Chart / Thread Activity]                                                  |
|   UI Thread    : [ VsyncProcessCallback ] -> [ Build ] -> [ Layout ] -> [ Paint ] |
|   Raster Thread: [ MessageLoop ] -> [ PipelineProduce ] -> [ GPURasterizer ]      |
+-----------------------------------------------------------------------------------+
|  [Detail Panel: CPU Profiler / Bottom-Up / Call Tree]                             |
|   Method Name: _LayarDaftarTugasPerformaState._hasil (Self Time: 1.2ms)           |
+-----------------------------------------------------------------------------------+
```

### A. Memahami Dua Thread Utama dalam Rendering Flutter
Saat menganalisis linimasa eksekusi, kenali pembagian tugas antara dua thread utama:

1. **UI Thread (Dart VM)**:
   - Bertanggung jawab mengeksekusi kode program Dart aplikasi Anda.
   - Menjalankan event handling, input sentuhan, pemanggilan method `build()`, penghitungan ukuran layout widget (*layout phase*), dan pencatatan instruksi grafis canvas (*paint phase*).
   - Simbol event utama: `Animate`, `Build`, `Layout`, `Paint`, dan `VsyncProcessCallback`.

2. **Raster Thread (GPU Thread)**:
   - Dulu dikenal dengan istilah GPU Thread. Thread ini dijalankan oleh engine C++ Flutter (Impeller atau Skia).
   - Mengambil pohon layer instruksi grafis yang diproduksi oleh UI thread dan menerjemahkannya ke dalam perintah primitif API grafis perangkat keras (seperti Vulkan, Metal, atau OpenGL).
   - Menghasilkan piksel akhir pada frame buffer layar.
   - Simbol event utama: `PipelineProduce`, `MessageLoop::RunExpiredTasks`, dan `GPURasterizer::Draw`.

### B. Menggunakan Flame Chart
Flame Chart menampilkan aktivitas CPU dan GPU dari waktu ke waktu secara hierarkis:
- **Sumbu Horizontal (Waktu)**: Menunjukkan urutan peristiwa kronologis dari kiri ke kanan. Lebar suatu balok mencerminkan durasi eksekusi event tersebut dalam milidetik.
- **Sumbu Vertikal (Kedalaman Call Stack)**: Menunjukkan rantai pemanggilan fungsi. Fungsi yang berada di baris atas memanggil fungsi yang terletak tepat di bawahnya.
- **Navigasi Interaktif**:
  - Gunakan tombol `W`, `A`, `S`, `D` atau scroll mouse untuk memperbesar (*zoom-in*), memperkecil (*zoom-out*), dan menggeser linimasa horizontal.
  - Klik pada balok event tertentu untuk memunculkan panel rincian statistik waktu (*Duration*, *Self Time*, *Total Time*).

### C. Menggunakan CPU Profiler
Panel CPU Profiler melakukan *statistical sampling* terhadap tumpukan thread Dart untuk mengetahui fungsi mana yang paling banyak menyita waktu prosesor:
1. Klik tombol **Record** pada tab CPU Profiler sesaat sebelum Anda melakukan interaksi berat (misalnya mengetik kueri pencarian atau menggulir 1.000 item secara agresif).
2. Lakukan interaksi pada layar ponsel selama 3 hingga 5 detik.
3. Klik tombol **Stop**.
4. Pelajari tiga mode tampilan profil:
   - **Bottom-Up**: Menampilkan fungsi yang paling banyak memakan waktu pada tingkat atomik (*Self Time*). Sangat efektif untuk menemukan fungsi komputasi berat yang tersembunyi.
   - **Call Tree**: Menampilkan hierarki panggilan dari induk teratas ke anak terdalam (*Total Time*).
   - **Method Table**: Menampilkan tabel seluruh method yang dipanggil lengkap dengan persentase alokasi waktu CPU.

---

## 5. Mengidentifikasi dan Menganalisis Frame Jank

### Konsep Anggaran Waktu Frame (Frame Budget)
Agar mata manusia melihat animasi dan transisi sebagai gerakan yang halus tanpa patah-patah (*fluid 60 FPS atau 120 FPS*), sistem operasi harus memperbarui isi layar secara berkala sesuai frekuensi *refresh rate* perangkat:
- **Layar Standar 60 Hz**: Memiliki anggaran waktu maksimum **16.6 ms per frame** (1.000 ms / 60 frame = 16.66 ms).
- **Layar Cepat 120 Hz (High Refresh Rate / ProMotion)**: Memiliki anggaran waktu maksimum **8.3 ms per frame** (1.000 ms / 120 frame = 8.33 ms).

Jika komputasi pengolahan frame pada UI thread atau proses rasterisasi pada Raster thread membutuhkan waktu melebihi batas anggaran tersebut, frame tersebut akan terlambat disajikan ke layar. Fenomena ini disebut sebagai **Frame Jank**.

### Visualisasi Frame pada DevTools Timeline
Di bagian atas tab Performance, setiap frame ditampilkan sebagai diagram batang vertikal:
- **Batang Berwarna Hijau / Biru Muda**: Frame sehat (*smooth frame*). Total pengerjaan komputasi berada jauh di bawah batas 16.6 ms (atau 8.3 ms).
- **Batang Berwarna Oranye**: Frame yang durasinya mendekati atau sedikit melewati ambang batas toleransi.
- **Batang Berwarna Merah**: Frame jank kritis. Pengguna akan merasakan animasi tersendat atau patah secara kasat mata.

```
Durasi Frame
   ^
   |        [Jank Kritis]
   |             |
25ms - - - - - -[ ]- - - - - - - - - - - - - - - - - -
   |            [ ]
16.6ms - - - - -[ ]- - - - - - - - - - - - - - - - - - Ambang 60 FPS
   |            [ ]     [Jank Ringan]
10ms - - - - - -[ ] - - - - -[ ]- - - - - - - - - - -
8.3ms- - - - - -[ ] - - - - -[ ]- - - - - - - - - - - Ambang 120 FPS
   |   [Normal] [ ]   [Normal][ ]
 0ms +---[ ]----[ ]-----[ ]---[ ]---------------------> Waktu
```

### Prosedur Mengisolasi Akar Masalah Jank
Ketika Anda menemukan batang berwarna merah pada linimasa:
1. **Klik pada batang merah tersebut**: DevTools akan menyorot rincian alokasi waktu frame tersebut di panel bawah.
2. **Evaluasi Breakdown Waktu**:
   - Perhatikan perbandingan nilai **UI Duration** dan **Raster Duration**.
3. **Skenario A: UI Duration Lebih Besar dari Ambang Batas (UI Thread Bottleneck)**:
   - Masalah berada pada kode logika Dart Anda.
   - *Penyebab umum*:
     - Perhitungan sinkron yang rumit di dalam method `build()`.
     - Melakukan filter, pengurutan (*sorting*), atau iterasi koleksi ribuan objek di UI thread tanpa latar belakang (*isolate*).
     - Menggunakan eager loading (membangun seluruh 1.000 widget kartu sekaligus menggunakan `Column` atau `SingleChildScrollView`).
   - *Langkah perbaikan*:
     - Ganti konstruksi list menjadi `ListView.builder` agar rendering bersifat *lazy*.
     - Delegasikan parsing atau komputasi matematis berat ke fungsi `compute()` atau `Isolate`.
     - Gunakan `const` constructor pada widget yang konfigurasinya statis.
4. **Skenario B: Raster Duration Lebih Besar dari Ambang Batas (Raster Thread Bottleneck)**:
   - Masalah berada pada tingkat instruksi grafis kartu visual (GPU).
   - *Penyebab umum*:
     - Terlalu banyak efek visual berat tanpa isolasi (misalnya efek `BackdropFilter` blur dinamis, bayangan berlapis, atau clipping melengkung ekstrem).
     - Memuat dan merender aset gambar beresolusi raksasa (misal 4000x3000 piksel) langsung ke dalam kartu avatar kecil tanpa mendefinisikan parameter `cacheWidth` atau `cacheHeight`.
     - Overdraw dan rekalkulasi grafis yang meluas ke seluruh layar karena ketiadaan `RepaintBoundary`.
   - *Langkah perbaikan*:
     - Bungkus subtree yang dinamis dengan `RepaintBoundary`.
     - Batasi resolusi decoding gambar sesuai ukuran piksel fisik layar.
     - Hindari penggunaan opacity atau clipping berlapis jika dapat digantikan oleh kontainer dekoratif sederhana.

---

## 6. Menggunakan Track Widget Rebuilds

Fitur **Track Widget Rebuilds** pada Flutter DevTools memungkinkan pengembang melihat secara transparan widget mana saja di pohon widget yang dipanggil ulang method `build()`-nya serta berapa kali pemanggilan tersebut terjadi selama interaksi pengguna berlangsung.

### Cara Mengaktifkan Track Widget Rebuilds
1. Buka Flutter DevTools, lalu pilih tab **Flutter Inspector**.
2. Pada panel toolbar bagian atas Flutter Inspector, klik tombol berlabel **Track Widget Rebuilds** (ikon panah melingkar berulang).
3. Setelah diaktifkan, kolom **Rebuild count** akan muncul di sebelah nama setiap kelas widget pada panel pohon widget.

```
Widget Tree                                  Rebuild Count
----------------------------------------------------------
LayarDaftarTugasPerforma ................... 4
  Scaffold ................................. 4
    Column ................................. 4
      TextField [task-search] .............. 4
      Wrap ................................. 4
        FilterChip (Aktif) ................. 4
      ListView.builder [task-list] ......... 4
        _KartuTugas (item 1) ............... 1
        _KartuTugas (item 2) ............... 1
          _IkonTugas [const] ............... 0 (Terselamatkan)
          _StatusBadge ..................... 1
```

### Praktikum Pengamatan Rebuild pada Modul 11
Lakukan uji coba berikut pada aplikasi Modul 11:
1. **Skenario Mengetik di Kolom Pencarian**:
   - Ketikkan satu kata kunci, misalnya "Mobile".
   - Perhatikan counter rebuild: State `_kueri` diperbarui melalui `setState()`, memicu rebuild pada `LayarDaftarTugasPerforma`.
   - Perhatikan daftar kartu di bawahnya: Hanya kartu tugas yang lolos seleksi kueri yang akan dibangun ulang di viewport.
2. **Skenario Mengubah Filter Status**:
   - Klik chip "Selesai", lalu amati bagaimana koleksi `_hasil` dievaluasi ulang.
   - Berkat pemisahan sub-widget yang modular, item yang tidak berubah tidak memicu pembuatan objek berulang yang sia-sia.

### Peran `const` Constructor dalam Mengeliminasi Rebuild
Pada Modul 11, perhatikan implementasi widget `_IkonTugas`:
```dart
class _IkonTugas extends StatelessWidget {
  const _IkonTugas();

  @override
  Widget build(BuildContext context) => const CircleAvatar(
        child: Icon(Icons.assignment_outlined),
      );
}
```
Ketika `_KartuTugas` di-rebuild, properti `leading` memanggil `const _IkonTugas()`. Karena widget ini bertanda `const`:
1. Flutter mengenali bahwa instansiasi widget ini bersifat kanonikal (*compile-time constant*).
2. Element tree memeriksa kesamaan identitas objek (`identical(oldWidget, newWidget)` menghasilkan `true`).
3. Framework Flutter **melewati total** pemanggilan method `build()` untuk sub-tree ikon tersebut. Nilai rebuild count pada DevTools tetap bernilai 0.

---

## 7. Menggunakan Repaint Rainbow dan RepaintBoundary

Proses rendering Flutter memisahkan antara tahapan **Build** (mengonstruksi pohon konfigurasi widget) dengan tahapan **Paint** (menggambar piksel nyata ke kanvas grafis). Suatu widget bisa saja mengalami rebuild tanpa harus dicat ulang, atau sebaliknya, mengalami repaint tanpa perlu rebuild.

### Apa itu Repaint Rainbow?
Repaint Rainbow adalah alat visualisasi interaktif yang menggambar garis batas tepi (*border*) dengan warna-warni kontras pada setiap lapisan render (*render layer*) yang sedang dicat ulang oleh engine Flutter.

Setiap kali suatu area layar mengalami proses paint ulang, garis batasnya akan berganti warna secara acak (merah, hijau muda, biru elektrik, kuning, oranye, ungu).

### Cara Mengaktifkan Repaint Rainbow

#### Cara A: Melalui Flutter DevTools
1. Buka tab **Flutter Inspector**.
2. Pada panel atas, cari tombol toggle berlabel **Highlight Repaints** (atau ikon pelangi).
3. Klik tombol tersebut menjadi aktif (*highlighted*). Layar aplikasi pada perangkat fisik akan langsung menampilkan garis batas berwarna di sekitar elemen antarmuka.

#### Cara B: Mengaktifkan Melalui Kode Dart (Saat Debug / Profiling)
Anda juga dapat mengaktifkan fitur ini secara langsung dari kode Dart dengan mengimpor pustaka rendering:
```dart
import 'package:flutter/rendering.dart';

void main() {
  // Aktifkan visualisasi batas repaint warna-warni
  debugRepaintRainbowEnabled = true;
  runApp(const Modul11App());
}
```

### Menginterpretasikan Visualisasi Warna Repaint
1. **Perilaku Ideal**:
   - Saat pengguna mengetik di `TextField`, hanya kursor teks yang berkedip dan kotak input pencarian yang memperbarui warna bordernya.
   - Area daftar tugas di bawahnya tidak boleh ikut berganti warna garis batas jika tidak ada perubahan data atau posisi scroll.
2. **Perilaku Bermasalah (*Repaint Cascade*)**:
   - Jika setiap kali kursor teks berkedip, seluruh layar dari AppBar hingga ke item paling bawah ikut berkedip berganti warna-warni, berarti seluruh halaman berada dalam satu lapisan cat raksasa tanpa isolasi. Hal ini membuang siklus GPU secara sia-sia.

### Mengisolasi Lapisan Render Menggunakan `RepaintBoundary`
Untuk menghentikan perambatan pengecatan ulang yang tidak perlu, Flutter menyediakan widget `RepaintBoundary`:
- `RepaintBoundary` menciptakan node `RenderRepaintBoundary` di pohon render.
- Node ini membuat layer visual bitmap terpisah (*composited layer*).
- Ketika subtree di dalam boundary berubah, hanya layer lokal tersebut yang dicat ulang. Lapisan di luar boundary cukup digabungkan ulang (*composited*) oleh GPU tanpa perlu menjalankan instruksi paint dari awal.

Contoh penerapan isolasi pada widget yang sering berubah atau memiliki visual kompleks:
```dart
RepaintBoundary(
  child: KartuTugasKompleks(tugas: tugas),
)
```
*Catatan Penting*: Jangan membungkus setiap widget kecil dengan `RepaintBoundary`. Pembuatan layer bitmap mengonsumsi memori GPU tambahan. Gunakan `RepaintBoundary` hanya pada area yang sering dianimasikan atau widget yang proses menggambarnya mahal (seperti custom canvas painter atau chart analitik).

---

## 8. Panduan Langkah demi Langkah Praktikum Mandiri Mahasiswa

Berikut adalah lembar kerja instruksional yang dapat diikuti mahasiswa secara mandiri di laboratorium komputer atau perangkat kerja masing-masing:

### Skenario Praktikum 1: Evaluasi Fling Scrolling pada 1.000 Item
1. Pastikan aplikasi berjalan pada **Profile Mode** di perangkat fisik.
2. Buka DevTools di peramban, buka tab **Performance**.
3. Klik tombol **Clear** (ikon tempat sampah) untuk membersihkan rekaman frame sebelumnya.
4. Lakukan sapuan jari secara cepat (*fast fling scroll*) dari bagian atas daftar menuju bagian bawah daftar tugas.
5. Biarkan list bergulir hingga berhenti dengan sendirinya.
6. Periksa linimasa frame:
   - Amati apakah terdapat batang berwarna oranye atau merah.
   - Bandingkan performa implementasi `ListView.builder` saat ini dengan skenario eager loading (jika seluruh 1.000 widget dimuat serentak).
   - Catat rata-rata waktu komputasi frame selama proses scrolling aktif.

### Skenario Praktikum 2: Evaluasi Pencarian Real-Time dan Filtering
1. Pada DevTools, buka panel **CPU Profiler**.
2. Klik tombol **Record**.
3. Pada aplikasi ponsel, ketikkan kata kunci pencarian di kolom `TextField`: "Sistem Operasi".
4. Klik FilterChip "Aktif".
5. Ubah dropdown filter mata kuliah menjadi "Sistem Operasi".
6. Klik tombol **Stop** pada CPU Profiler.
7. Pilih tab **Bottom-Up** dan periksa baris method:
   - Cari fungsi `_LayarDaftarTugasPerformaState._hasil`.
   - Amati nilai *Self Time*: Verifikasi bahwa eksekusi fungsi filter memori terhadap 1.000 item berlangsung sangat cepat (< 2 ms) sehingga tidak memblokir kelancaran input keyboard pengguna.

### Skenario Praktikum 3: Evaluasi Rebuild dan Repaint pada Modul 11
1. Buka tab **Flutter Inspector**, lalu aktifkan **Track Widget Rebuilds** dan **Highlight Repaints**.
2. Hapus teks pencarian menggunakan tombol silang pada text field.
3. Amati perubahan border warna pada layar perangkat.
4. Konfirmasikan bahwa komponen `_IkonTugas` dengan konstruktor `const` tidak mengalami rebuild ulang.
5. Konfirmasikan bahwa badge status hanya dicat ulang jika status tugas yang bersangkutan mengalami perubahan.

---

## 9. Rangkuman Tindakan Optimasi dan Checklist Verifikasi

### Tabel Matriks Diagnosa Masalah Performa

| Gejala DevTools | Bagian yang Terindikasi | Akar Penyebab Umum | Solusi Rekayasa |
| :--- | :--- | :--- | :--- |
| **Batang Merah (UI Duration tinggi)** | UI Thread (Dart VM) | List 1.000 item dimuat eager (`Column`/`SingleChildScrollView`) | Migrasi ke `ListView.builder` atau `CustomScrollView` |
| **Batang Merah (UI Duration tinggi)** | UI Thread (Dart VM) | Pemrosesan data sinkron di dalam method `build()` | Pindahkan komputasi ke background `Isolate` atau fungsi `compute()` |
| **Rebuild Counter melonjak tinggi** | Element / Widget Tree | Memanggil `setState()` di tingkat parent root tanpa modularisasi widget | Ekstraksi sub-widget mandiri dan gunakan `const` constructor |
| **Batang Merah (Raster Duration tinggi)**| Raster Thread (GPU) | Overdraw dan efek blur/masking berlebih | Isolasi layer menggunakan `RepaintBoundary` dan kurangi efek visual berat |
| **Memori Heap melonjak saat scroll** | Dart Heap Memory | Objek widget tidak didaur ulang saat keluar viewport | Pastikan list menggunakan sliver view yang mendukung daur ulang elemen |

### Checklist Kesiapan Performa Sebelum Rilis Produksi
Sebelum kode aplikasi dinyatakan siap untuk tahap rilis final, pastikan seluruh kriteria berikut terpenuhi:
- [ ] Pengujian performa telah diverifikasi pada **Profile Mode** di perangkat fisik nyata, bukan simulator debug.
- [ ] Seluruh daftar data dinamis berskala besar (>= 50 item) diimplementasikan dengan `ListView.builder` atau `SliverList`.
- [ ] Widget yang memiliki parameter statis telah dideklarasikan menggunakan konstruktor `const`.
- [ ] Nilai *frame time* pada pengujian scrolling stabil di bawah ambang batas (16.6 ms pada layar 60 Hz).
- [ ] Tidak ada komputasi berat, manipulasi string massal, atau parsing I/O yang berjalan sinkron di UI thread.
- [ ] Fitur pencarian dan filter teks merespons ketikan pengguna secara instan tanpa memicu frame freeze.
- [ ] Hasil audit linimasa DevTools bebas dari frame jank kritis yang berulang.
