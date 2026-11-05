import 'package:flutter/material.dart';

void main() {
  runApp(const Modul11App());
}

enum StatusTugas { aktif, selesai }

class TugasPerforma {
  const TugasPerforma({required this.nomor, required this.mataKuliah, required this.status});

  final int nomor;
  final String mataKuliah;
  final StatusTugas status;

  String get judul => 'Tugas praktikum ${nomor.toString().padLeft(4, '0')}';
}

class Modul11App extends StatelessWidget {
  const Modul11App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Modul 11: Optimasi Daftar Tugas',
        theme: ThemeData(colorSchemeSeed: const Color(0xFF0E7490), useMaterial3: true),
        home: const LayarDaftarTugasPerforma(),
      );
}

class LayarDaftarTugasPerforma extends StatefulWidget {
  const LayarDaftarTugasPerforma({super.key});

  @override
  State<LayarDaftarTugasPerforma> createState() => _LayarDaftarTugasPerformaState();
}

class _LayarDaftarTugasPerformaState extends State<LayarDaftarTugasPerforma> {
  final TextEditingController _pencarian = TextEditingController();
  static const List<String> daftarMataKuliah = [
    'Pemrograman Mobile',
    'Basis Data',
    'Jaringan Komputer',
    'Rekayasa Perangkat Lunak',
    'Sistem Operasi',
    'Kecerdasan Buatan',
    'Pemrograman Web',
    'Analisis dan Perancangan Sistem',
  ];
  final List<TugasPerforma> _semuaTugas = List<TugasPerforma>.generate(
    1000,
    (index) => TugasPerforma(
      nomor: index + 1,
      mataKuliah: daftarMataKuliah[index % 8],
      status: (index + 1) % 4 == 0 ? StatusTugas.selesai : StatusTugas.aktif,
    ),
  );
  StatusTugas? _filter;
  String? _filterMataKuliah;
  String _kueri = '';

  List<TugasPerforma> get _hasil {
    // Kueri cukup diubah ke huruf kecil sekali per build, bukan sekali per item.
    final kueri = _kueri.toLowerCase();
    if (_filter == null && _filterMataKuliah == null && kueri.isEmpty) {
      return _semuaTugas;
    }
    return _semuaTugas.where((tugas) {
      if (_filter != null && tugas.status != _filter) return false;
      if (_filterMataKuliah != null && tugas.mataKuliah != _filterMataKuliah) {
        return false;
      }
      if (kueri.isEmpty) return true;
      return '${tugas.judul} ${tugas.mataKuliah}'.toLowerCase().contains(kueri);
    }).toList(growable: false);
  }
  @override
  void dispose() {
    _pencarian.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasil = _hasil;
    return Scaffold(
      appBar: AppBar(title: const Text('Tugas Kuliah')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              key: const ValueKey('task-search'),
              controller: _pencarian,
              onChanged: (value) => setState(() => _kueri = value),
              decoration: InputDecoration(
                labelText: 'Cari tugas atau mata kuliah',
                hintText: 'Cari berdasarkan judul atau mata kuliah',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _kueri.isNotEmpty
                    ? IconButton(
                        key: const ValueKey('clear-search'),
                        icon: const Icon(Icons.clear),
                        tooltip: 'Hapus pencarian',
                        onPressed: () {
                          _pencarian.clear();
                          setState(() => _kueri = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              children: [
                _filterChip('Semua', null),
                _filterChip('Aktif', StatusTugas.aktif),
                _filterChip('Selesai', StatusTugas.selesai),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Filter Mata Kuliah',
                prefixIcon: Icon(Icons.school_outlined),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  key: const ValueKey('filter-mata-kuliah'),
                  value: _filterMataKuliah,
                  isDense: false,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Semua Mata Kuliah'),
                    ),
                    ...daftarMataKuliah.map(
                      (mk) => DropdownMenuItem<String?>(
                        value: mk,
                        child: Text(mk),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _filterMataKuliah = value),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Text(
              'Menampilkan ${hasil.length} dari ${_semuaTugas.length} tugas',
              key: const ValueKey('result-count'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: hasil.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tidak ada tugas yang cocok.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    key: const ValueKey('task-list'),
                    itemCount: hasil.length,
                    itemBuilder: (context, index) => _KartuTugas(tugas: hasil[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, StatusTugas? status) {
    final isSelected = _filter == status;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      onSelected: (_) => setState(() => _filter = status),
    );
  }
}

class _KartuTugas extends StatelessWidget {
  const _KartuTugas({required this.tugas});

  final TugasPerforma tugas;

  @override
  Widget build(BuildContext context) => Card(
        key: ValueKey('task-card-${tugas.nomor}'),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: ListTile(
          leading: const _IkonTugas(),
          title: Text(tugas.judul),
          subtitle: Text(tugas.mataKuliah),
          trailing: _StatusBadge(status: tugas.status),
        ),
      );
}

class _IkonTugas extends StatelessWidget {
  const _IkonTugas();

  @override
  Widget build(BuildContext context) => const CircleAvatar(
        child: Icon(Icons.assignment_outlined),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final StatusTugas status;

  @override
  Widget build(BuildContext context) {
    final isSelesai = status == StatusTugas.selesai;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelesai ? const Color(0xFFDCFCE7) : const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelesai ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
          width: 1,
        ),
      ),
      child: Text(
        isSelesai ? 'Selesai' : 'Aktif',
        style: TextStyle(
          color: isSelesai ? const Color(0xFF14532D) : const Color(0xFF0C4A6E),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
