import 'package:flutter/material.dart';
import 'package:poliwangi_mobile_starter/modul_06/services/auth_api.dart';
import 'package:poliwangi_mobile_starter/modul_06/services/sesi_memori.dart';
import 'controllers/sesi_controller.dart';
import 'repositories/aman_sesi_repository.dart';
import 'repositories/memori_sesi_repository.dart';
import 'repositories/prefs_sesi_repository.dart';
import 'repositories/sesi_repository.dart';
import 'screens/beranda_pengayaan_screen.dart';
import 'screens/login_pengayaan_screen.dart';
import 'widgets/gerbang_sesi.dart';

/// Titik masuk aplikasi Fase B (Pengayaan):
/// Menyediakan penukaran backend penyimpanan (Memori vs Prefs vs Aman)
/// dan menggunakan GerbangSesi secara deklaratif.
class Modul06PengayaanApp extends StatefulWidget {
  final AuthApi? api;
  final SesiRepository? repositoryAwal;
  final VoidCallback? onGantiMode;

  const Modul06PengayaanApp({
    super.key,
    this.api,
    this.repositoryAwal,
    this.onGantiMode,
  });

  @override
  State<Modul06PengayaanApp> createState() => _Modul06PengayaanAppState();
}

class _Modul06PengayaanAppState extends State<Modul06PengayaanApp> {
  late final AuthApi _api = widget.api ?? const AuthApi();
  late final MemoriSesiRepository _memoriRepo =
      MemoriSesiRepository(SesiMemori());
  late final PrefsSesiRepository _prefsRepo = PrefsSesiRepository();
  late final AmanSesiRepository _amanRepo = AmanSesiRepository();

  late final SesiController _controller;

  @override
  void initState() {
    super.initState();
    final awal = widget.repositoryAwal ?? _amanRepo;
    _controller = SesiController(repository: awal, api: _api);
    _controller.pulihkan();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _gantiPenyimpanan(String nama) {
    switch (nama) {
      case 'Memori':
        _controller.gantiRepository(_memoriRepo);
        break;
      case 'Prefs':
        _controller.gantiRepository(_prefsRepo);
        break;
      case 'Aman':
      default:
        _controller.gantiRepository(_amanRepo);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Modul 06: Pengayaan (Fase B)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: GerbangSesi(
        controller: _controller,
        form: (context) => LoginPengayaanScreen(
          controller: _controller,
          onPilihPenyimpanan: _gantiPenyimpanan,
          onGantiMode: widget.onGantiMode,
        ),
        beranda: (context, sesi) => BerandaPengayaanScreen(
          controller: _controller,
          sesi: sesi,
          onPilihPenyimpanan: _gantiPenyimpanan,
          onGantiMode: widget.onGantiMode,
        ),
      ),
    );
  }
}
