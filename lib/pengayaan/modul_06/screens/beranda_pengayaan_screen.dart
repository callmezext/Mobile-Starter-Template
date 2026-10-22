import 'dart:async';
import 'package:flutter/material.dart';
import 'package:poliwangi_mobile_starter/modul_06/models/sesi_pengguna.dart';
import 'package:poliwangi_mobile_starter/modul_06/widgets/kartu_sesi.dart';
import '../controllers/sesi_controller.dart';
import '../widgets/papan_diagnostik_penyimpanan.dart';

/// Beranda Fase B: menampilkan sesi terenkripsi, tombol refresh token,
/// dan papan diagnostik intip mentah.
class BerandaPengayaanScreen extends StatefulWidget {
  final SesiController controller;
  final SesiPengguna sesi;
  final ValueChanged<String>? onPilihPenyimpanan;
  final VoidCallback? onGantiMode;

  const BerandaPengayaanScreen({
    super.key,
    required this.controller,
    required this.sesi,
    this.onPilihPenyimpanan,
    this.onGantiMode,
  });

  @override
  State<BerandaPengayaanScreen> createState() => _BerandaPengayaanScreenState();
}

class _BerandaPengayaanScreenState extends State<BerandaPengayaanScreen> {
  Timer? _timer;
  bool _sedangPerbarui = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _perbaruiToken() async {
    setState(() => _sedangPerbarui = true);
    await widget.controller.perbaruiSesi();
    if (!mounted) return;
    setState(() => _sedangPerbarui = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Masa berlaku sesi berhasil diperbarui.'),
        backgroundColor: Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modul 06: Fase B (Secure Storage)'),
        backgroundColor: theme.colorScheme.secondaryContainer,
        actions: [
          if (widget.onGantiMode != null)
            TextButton.icon(
              onPressed: widget.onGantiMode,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Pindah ke Fase A'),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Beranda Mahasiswa',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Penyimpanan aktif: ${widget.controller.repository.nama}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Kartu ringkasan sesi aktif
            KartuSesi(
              sesi: widget.sesi,
              sekarang: widget.controller.jam(),
              onKeluar: widget.controller.keluar,
              sedangKeluar: false,
            ),
            const SizedBox(height: 14),

            // Tombol Perbarui Masa Berlaku Sesi (Simulasi Refresh Token)
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _sedangPerbarui ? null : _perbaruiToken,
                icon: _sedangPerbarui
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.autorenew_rounded),
                label: Text(_sedangPerbarui
                    ? 'Memperbarui sesi…'
                    : 'Perbarui Masa Berlaku Sesi'),
              ),
            ),
            const SizedBox(height: 20),

            // Papan Diagnostik untuk membuktikan token di memori vs prefs vs aman
            PapanDiagnostikPenyimpanan(
              repository: widget.controller.repository,
              onPilihPenyimpanan: widget.onPilihPenyimpanan,
            ),
          ],
        ),
      ),
    );
  }
}
