import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sesi_pengguna.dart';
import '../services/auth_api.dart';
import '../services/sesi_memori.dart';
import '../widgets/field_kata_sandi.dart';
import '../widgets/kartu_sesi.dart';

enum StatusAuth { memeriksa, keluar, memproses, masuk, gagal }

class LoginScreen extends StatefulWidget {
  final AuthApi api;
  final SesiMemori sesiMemori;
  final DateTime Function() jam;
  final VoidCallback? onGantiMode;

  const LoginScreen({
    super.key,
    required this.api,
    required this.sesiMemori,
    this.jam = DateTime.now,
    this.onGantiMode,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _sandi = TextEditingController();

  StatusAuth _status = StatusAuth.memeriksa;
  String? _pesanGagal;
  SesiPengguna? _sesi;
  bool _sedangKeluar = false;
  Timer? _timerHitungMundur;

  @override
  void initState() {
    super.initState();
    _pulihkanSesi();
  }

  @override
  void dispose() {
    _timerHitungMundur?.cancel();
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  void _mulaiTimerHitungMundur() {
    _timerHitungMundur?.cancel();
    _timerHitungMundur = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_sesi != null && _sesi!.sudahKedaluwarsa(widget.jam())) {
        _keluarOtomatisKedaluwarsa();
      } else {
        setState(() {}); // Memperbarui tampilan sisa detik di KartuSesi
      }
    });
  }

  Future<void> _keluarOtomatisKedaluwarsa() async {
    _timerHitungMundur?.cancel();
    await widget.sesiMemori.hapus();
    if (!mounted) return;
    setState(() {
      _sesi = null;
      _status = StatusAuth.gagal;
      _pesanGagal = 'Sesi Anda telah berakhir. Silakan masuk kembali.';
    });
  }

  Future<void> _pulihkanSesi() async {
    final SesiPengguna? tersimpan = widget.sesiMemori.baca();
    if (!mounted) return;

    if (tersimpan == null) {
      setState(() => _status = StatusAuth.keluar);
      return;
    }

    if (tersimpan.sudahKedaluwarsa(widget.jam())) {
      await widget.sesiMemori.hapus();
      if (!mounted) return;
      setState(() {
        _status = StatusAuth.gagal;
        _pesanGagal = 'Sesi sebelumnya sudah berakhir. Silakan masuk lagi.';
      });
      return;
    }

    setState(() {
      _sesi = tersimpan;
      _status = StatusAuth.masuk;
    });
    _mulaiTimerHitungMundur();
  }

  Future<void> _kirim() async {
    if (_status == StatusAuth.memproses) return; // Cegah kirim ganda (Lapis 1).
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _status = StatusAuth.memproses;
      _pesanGagal = null;
    });

    try {
      final SesiPengguna hasil = await widget.api.masuk(
        email: _email.text,
        sandi: _sandi.text,
      );
      await widget.sesiMemori.simpan(hasil);
      if (!mounted) return;
      setState(() {
        _sesi = hasil;
        _status = StatusAuth.masuk;
        _sandi.clear(); // Bersihkan kata sandi dari memori controller.
      });
      _mulaiTimerHitungMundur();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = StatusAuth.gagal;
        _pesanGagal = e.pesan;
      });
    } catch (e) {
      // Kesalahan tak terduga TIDAK dibocorkan ke layar.
      if (!mounted) return;
      setState(() {
        _status = StatusAuth.gagal;
        _pesanGagal = 'Terjadi kesalahan tak terduga. Coba lagi.';
      });
      debugPrint('Login gagal tak terduga: $e');
    }
  }

  Future<void> _keluar() async {
    _timerHitungMundur?.cancel();
    setState(() => _sedangKeluar = true);
    await widget.sesiMemori.hapus();
    if (!mounted) return;
    setState(() {
      _sesi = null;
      _status = StatusAuth.keluar; // Bukan StatusAuth.gagal.
      _pesanGagal = null;
      _sedangKeluar = false;
      _email.clear();
      _sandi.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modul 06: Fase A (Sesi Memori)'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          if (widget.onGantiMode != null)
            TextButton.icon(
              onPressed: widget.onGantiMode,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Pindah ke Fase B'),
            ),
        ],
      ),
      body: SafeArea(child: _bangunIsi()),
    );
  }

  /// Satu-satunya tempat yang memutuskan layar mana yang tampil.
  Widget _bangunIsi() {
    switch (_status) {
      case StatusAuth.memeriksa:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memeriksa sesi tersimpan…'),
            ],
          ),
        );
      case StatusAuth.masuk:
        final SesiPengguna? sesi = _sesi;
        if (sesi == null) {
          return _bangunForm();
        }
        return _bangunBeranda(sesi);
      case StatusAuth.keluar:
      case StatusAuth.memproses:
      case StatusAuth.gagal:
        return _bangunForm();
    }
  }

  Widget _bangunForm() {
    final bool sibuk = _status == StatusAuth.memproses;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        const SizedBox(height: 8),
        const Text(
          'Masuk ke Portal Akademik',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Fase A: Sesi disimpan di memori RAM proses',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 24),

        // Pesan kegagalan
        if (_pesanGagal != null) ...<Widget>[
          _KotakPesan(pesan: _pesanGagal!),
          const SizedBox(height: 16),
        ],

        Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _email,
                enabled: !sibuk,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.email],
                validator: _validasiEmail,
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
                validator: (String? nilai) {
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
            // Dua lapis penjaga: penjaga logika di _kirim & tombol mati saat sibuk
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
        _KotakInfoDemo(
          onIsiOtomatis: sibuk
              ? null
              : () => setState(() {
                    _email.text = AuthApi.emailDemo;
                    _sandi.text = AuthApi.sandiDemo;
                  }),
        ),
      ],
    );
  }

  static String? _validasiEmail(String? nilai) {
    final String teks = (nilai ?? '').trim();
    if (teks.isEmpty) return 'Email wajib diisi.';
    if (!teks.contains('@') || !teks.contains('.')) {
      return 'Format email belum benar.';
    }
    return null;
  }

  Widget _bangunBeranda(SesiPengguna sesi) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        const Text(
          'Beranda Mahasiswa',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Status autentikasi aktif (Fase A)',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        KartuSesi(
          sesi: sesi,
          sekarang: widget.jam(),
          onKeluar: _keluar,
          sedangKeluar: _sedangKeluar,
        ),
        const SizedBox(height: 20),
        const _KotakPeringatanMemori(),
      ],
    );
  }
}

class _KotakPesan extends StatelessWidget {
  final String pesan;
  const _KotakPesan({required this.pesan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.error.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pesan,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KotakInfoDemo extends StatelessWidget {
  final VoidCallback? onIsiOtomatis;
  const _KotakInfoDemo({this.onIsiOtomatis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Akun Pengujian:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              if (onIsiOtomatis != null)
                TextButton(
                  onPressed: onIsiOtomatis,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  child: const Text('Isi Akun Uji'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('• Berhasil: student@trpl.test / belajar123',
              style: TextStyle(fontSize: 12)),
          const Text('• Akun Terkunci: terkunci@trpl.test (423)',
              style: TextStyle(fontSize: 12)),
          const Text('• Server Gangguan: gangguan@trpl.test (503)',
              style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _KotakPeringatanMemori extends StatelessWidget {
  const _KotakPeringatanMemori();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.memory_rounded,
              color: theme.colorScheme.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan Sesi RAM:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sesi tersimpan di memori RAM proses. Jika aplikasi ditutup dari task manager dan dibuka kembali, sesi akan terhapus.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
