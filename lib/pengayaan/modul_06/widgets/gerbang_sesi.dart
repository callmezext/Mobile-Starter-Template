import 'package:flutter/material.dart';
import 'package:poliwangi_mobile_starter/modul_06/models/sesi_pengguna.dart';
import '../controllers/sesi_controller.dart';

typedef FormBuilder = Widget Function(BuildContext context);
typedef BerandaBuilder = Widget Function(
    BuildContext context, SesiPengguna sesi);

/// Gerbang sesi terpusat: menentukan tampilan layar berdasarkan status SesiController.
/// Memastikan tidak ada layar yang tertinggal tanpa validasi status sesi.
class GerbangSesi extends StatelessWidget {
  final SesiController controller;
  final FormBuilder form;
  final BerandaBuilder beranda;

  const GerbangSesi({
    super.key,
    required this.controller,
    required this.form,
    required this.beranda,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        switch (controller.status) {
          case StatusSesi.memeriksa:
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Memeriksa status sesi tersimpan…'),
                  ],
                ),
              ),
            );
          case StatusSesi.masuk:
            final sesi = controller.sesi;
            if (sesi == null) {
              return form(context);
            }
            return beranda(context, sesi);
          case StatusSesi.keluar:
          case StatusSesi.memproses:
          case StatusSesi.gagal:
          case StatusSesi.kedaluwarsa:
            return form(context);
        }
      },
    );
  }
}
