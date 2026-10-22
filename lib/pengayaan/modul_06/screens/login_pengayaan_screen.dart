import 'package:flutter/material.dart';
import 'package:poliwangi_mobile_starter/modul_06/services/auth_api.dart';
import 'package:poliwangi_mobile_starter/modul_06/widgets/field_kata_sandi.dart';
import '../controllers/sesi_controller.dart';
import '../widgets/papan_diagnostik_penyimpanan.dart';

/// Layar login Fase B: tidak menyimpan state kebenaran sendiri.
/// Seluruh state autentikasi didelegasikan kepada SesiController.
class LoginPengayaanScreen extends StatefulWidget {
  final SesiController controller;
  final ValueChanged<String>? onPilihPenyimpanan;
  final VoidCallback? onGantiMode;

  const LoginPengayaanScreen({
    super.key,
    required this.controller,
    this.onPilihPenyimpanan,
    this.onGantiMode,
  });

  @override
  State<LoginPengayaanScreen> createState() => _LoginPengayaanScreenState();
}

class _LoginPengayaanScreenState extends State<LoginPengayaanScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _sandi = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  void _kirim() {
    if (widget.controller.status == StatusSesi.memproses) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.controller.masuk(
      email: _email.text,
      sandi: _sandi.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool sibuk = widget.controller.status == StatusSesi.memproses;
    final String? pesanError = widget.controller.pesan;
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
              'Masuk ke Portal Akademik',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Fase B: Sesi Controller & Penyimpanan Aman Platform',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),

            // Papan Diagnostik untuk switch backend penyimpanan
            PapanDiagnostikPenyimpanan(
              repository: widget.controller.repository,
              onPilihPenyimpanan: widget.onPilihPenyimpanan,
            ),
            const SizedBox(height: 16),

            // Tampilkan pesan error jika ada
            if (pesanError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        pesanError,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _email,
                    enabled: !sibuk,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: (nilai) {
                      final teks = (nilai ?? '').trim();
                      if (teks.isEmpty) return 'Email wajib diisi.';
                      if (!teks.contains('@') || !teks.contains('.')) {
                        return 'Format email belum benar.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FieldKataSandi(
                    controller: _sandi,
                    enabled: !sibuk,
                    validator: (nilai) {
                      if (nilai == null || nilai.isEmpty) {
                        return 'Kata sandi wajib diisi.';
                      }
                      if (nilai.length < 8) {
                        return 'Kata sandi minimal 8 karakter.';
                      }
                      return null;
                    },
                    onSubmitted: _kirim,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: sibuk ? null : _kirim,
                icon: sibuk
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login_rounded),
                label: Text(sibuk ? 'Memproses…' : 'Masuk'),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Akun uji: student@trpl.test / belajar123',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: sibuk
                        ? null
                        : () {
                            _email.text = AuthApi.emailDemo;
                            _sandi.text = AuthApi.sandiDemo;
                          },
                    child: const Text('Isi Akun Uji'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
