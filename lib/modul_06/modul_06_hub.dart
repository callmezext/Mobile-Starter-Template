import 'package:flutter/material.dart';
import '../pengayaan/modul_06/modul_06_pengayaan_app.dart';
import 'modul_06_app.dart';

enum ModeModul06 { faseA, faseB }

/// Container switcher untuk memudahkan pergantian mode antara:
/// - Fase A (Praktikum Wajib: Sesi di Memori RAM Proses)
/// - Fase B (Pengayaan: Sesi di Penyimpanan Aman Platform & Papan Diagnostik)
class Modul06HubScreen extends StatefulWidget {
  const Modul06HubScreen({super.key});

  @override
  State<Modul06HubScreen> createState() => _Modul06HubScreenState();
}

class _Modul06HubScreenState extends State<Modul06HubScreen> {
  ModeModul06 _mode = ModeModul06.faseA;

  void _gantiKeFaseA() {
    setState(() => _mode = ModeModul06.faseA);
  }

  void _gantiKeFaseB() {
    setState(() => _mode = ModeModul06.faseB);
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == ModeModul06.faseA) {
      return Modul06App(
        onGantiMode: _gantiKeFaseB,
      );
    } else {
      return Modul06PengayaanApp(
        onGantiMode: _gantiKeFaseA,
      );
    }
  }
}
