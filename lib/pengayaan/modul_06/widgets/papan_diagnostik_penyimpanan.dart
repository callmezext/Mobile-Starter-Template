import 'package:flutter/material.dart';
import '../repositories/sesi_repository.dart';

/// Papan diagnostik untuk membuktikan perbedaan keamanan penyimpanan:
/// - Prefs (SharedPreferences): token terbaca jelas dalam bentuk teks mentah.
/// - Aman (FlutterSecureStorage): token terenkripsi dan tidak dapat diintip sembarangan.
class PapanDiagnostikPenyimpanan extends StatefulWidget {
  final SesiRepository repository;
  final ValueChanged<String>? onPilihPenyimpanan;

  const PapanDiagnostikPenyimpanan({
    super.key,
    required this.repository,
    this.onPilihPenyimpanan,
  });

  @override
  State<PapanDiagnostikPenyimpanan> createState() =>
      _PapanDiagnostikPenyimpananState();
}

class _PapanDiagnostikPenyimpananState
    extends State<PapanDiagnostikPenyimpanan> {
  String? _hasilIntip;
  bool _sudahMengintip = false;
  bool _sedangMengintip = false;

  Future<void> _intip() async {
    setState(() => _sedangMengintip = true);
    final String? hasil = await widget.repository.intipMentah();
    if (!mounted) return;
    setState(() {
      _hasilIntip = hasil;
      _sudahMengintip = true;
      _sedangMengintip = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String namaAktif = widget.repository.nama;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security_rounded,
                    color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Inspeksi Penyimpanan Sesi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Penyedia penyimpanan aktif:',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'Memori',
                  label: Text('Memori'),
                ),
                ButtonSegment<String>(
                  value: 'Prefs',
                  label: Text('Prefs'),
                ),
                ButtonSegment<String>(
                  value: 'Aman',
                  label: Text('Aman'),
                ),
              ],
              selected: {namaAktif},
              onSelectionChanged: (Set<String> baru) {
                setState(() {
                  _sudahMengintip = false;
                  _hasilIntip = null;
                });
                widget.onPilihPenyimpanan?.call(baru.first);
              },
            ),
            const SizedBox(height: 8),
            Text(
              widget.repository.keterangan,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Uji Pembacaan Langsung:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                FilledButton.tonal(
                  onPressed: _sedangMengintip ? null : _intip,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: _sedangMengintip
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Baca Data Mentah',
                          style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            if (_sudahMengintip) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _hasilIntip != null
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasilIntip != null
                          ? 'Data mentah terbaca (plaintext):'
                          : 'Data terlindungi (nilai mentah tidak dapat diakses):',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _hasilIntip != null
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      _hasilIntip ??
                          'null: data terlindungi enkripsi platform Keystore atau Keychain.',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: _hasilIntip != null
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
