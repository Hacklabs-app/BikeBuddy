import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _green = Color(0xFF00C853);
const _textDark = Color(0xFF0D1F0F);
const _textLight = Color(0xFF8FA891);

class ScanQrScreen extends ConsumerStatefulWidget {
  const ScanQrScreen({super.key});

  @override
  ConsumerState<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends ConsumerState<ScanQrScreen>
    with TickerProviderStateMixin {
  final MobileScannerController _scanCtrl = MobileScannerController();
  bool _scanned = false;
  bool _processing = false;
  String? _error;

  late AnimationController _scanLineCtrl;
  late Animation<double> _scanLineAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _scanLineCtrl =
        AnimationController(duration: const Duration(seconds: 2), vsync: this)
          ..repeat(reverse: true);
    _pulseCtrl = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this)
      ..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0.05, end: 0.95).animate(
        CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut));
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _scanLineCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String qrCode) async {
    if (_scanned || _processing) return;
    setState(() {
      _scanned = true;
      _processing = true;
      _error = null;
    });
    _scanCtrl.stop();
    HapticFeedback.mediumImpact();

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        context.go('/login');
        return;
      }

      // Find bike by QR code
      final bike = await supabase
          .from('bikes')
          .select('*, shops(name)')
          .eq('qr_code', qrCode)
          .maybeSingle();

      if (bike == null) throw Exception('Bike not found for this QR code.');
      if (bike['status'] != 'available' && bike['status'] != 'reserved') {
        throw Exception('This bike is not available (${bike['status']}).');
      }

      // Check if user has an active reservation for this bike
      final reservation = await supabase
          .from('rentals')
          .select()
          .eq('customer_id', user.id)
          .eq('bike_id', bike['id'] as String)
          .eq('status', 'reserved')
          .maybeSingle();

      final now = DateTime.now();

      if (reservation != null) {
        // Activate the reserved rental
        await supabase.from('rentals').update({
          'status': 'active',
          'checkout_time': now.toIso8601String(),
        }).eq('id', reservation['id'] as String);
      } else {
        // Walk-up: create new rental on the spot
        await supabase.from('rentals').insert({
          'bike_id': bike['id'],
          'customer_id': user.id,
          'shop_id': bike['shop_id'],
          'checkout_time': now.toIso8601String(),
          'hourly_rate': bike['hourly_rate'],
          'status': 'active',
        });
      }

      // Mark bike as rented
      await supabase
          .from('bikes')
          .update({'status': 'rented'}).eq('id', bike['id'] as String);

      if (mounted) {
        _showSuccessAndNavigate(
          bike['name'] as String? ?? 'Bike',
          (bike['shops'] as Map?)?['name'] as String? ?? 'Shop',
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _processing = false;
        _scanned = false;
      });
      _scanCtrl.start();
    }
  }

  void _showSuccessAndNavigate(String bikeName, String shopName) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80,
              height: 80,
              decoration:
                  const BoxDecoration(color: _green, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 44),
            ),
            const SizedBox(height: 20),
            const Text('Ride Started! 🚀',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _textDark)),
            const SizedBox(height: 8),
            Text('$bikeName from $shopName\nTimer is now running.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _textLight, fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/ride');
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('View Active Ride',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // Camera
        MobileScanner(
          controller: _scanCtrl,
          onDetect: (capture) {
            final barcode = capture.barcodes.firstOrNull;
            if (barcode?.rawValue != null) {
              _handleScan(barcode!.rawValue!);
            }
          },
        ),

        // Dark overlay with cutout
        CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ScanOverlayPainter(),
        ),

        // Scan line animation
        if (!_scanned)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanLineAnim,
              builder: (_, __) {
                final size = MediaQuery.of(context).size;
                final scanAreaSize = size.width * 0.7;
                final top = (size.height - scanAreaSize) / 2;
                return Positioned(
                  top: top + scanAreaSize * _scanLineAnim.value,
                  left: size.width * 0.15,
                  right: size.width * 0.15,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Colors.transparent,
                          _green,
                          Colors.transparent
                        ],
                      ),
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [
                        BoxShadow(
                            color: _green.withValues(alpha: 0.5), blurRadius: 8)
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        // Corner brackets
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.width * 0.7,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => CustomPaint(
                painter: _CornerPainter(opacity: _pulseAnim.value),
              ),
            ),
          ),
        ),

        // Top bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 18),
                ),
              ),
              const Spacer(),
              // Torch toggle
              GestureDetector(
                onTap: () => _scanCtrl.toggleTorch(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.flashlight_on,
                      color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
        ),

        // Bottom instructions
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.9),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(children: [
              if (_processing) ...[
                const CircularProgressIndicator(color: _green),
                const SizedBox(height: 16),
                const Text('Starting your ride...',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ] else if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.4))),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _error = null),
                  child: const Text('Try Again',
                      style: TextStyle(
                          color: _green, fontWeight: FontWeight.w700)),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _green.withValues(alpha: 0.3))),
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, color: _green, size: 18),
                        SizedBox(width: 10),
                        Text('Point at the bike\'s QR code to start',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ]),
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─── Painters ─────────────────────────────────────────────────────────────────

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scanSize = size.width * 0.7;
    final left = (size.width - scanSize) / 2;
    final top = (size.height - scanSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanSize, scanSize);

    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final path = Path()
      ..addRect(fullRect)
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter oldDelegate) => false;
}

class _CornerPainter extends CustomPainter {
  final double opacity;
  _CornerPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _green.withValues(alpha: opacity)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 24.0;
    const r = 12.0;

    // Top-left
    canvas.drawLine(const Offset(r, 0), const Offset(r + len, 0), paint);
    canvas.drawLine(const Offset(0, r), const Offset(0, r + len), paint);
    canvas.drawArc(const Rect.fromLTWH(0, 0, r * 2, r * 2), 3.14159,
        3.14159 / 2, false, paint);

    // Top-right
    canvas.drawLine(
        Offset(size.width - r, 0), Offset(size.width - r - len, 0), paint);
    canvas.drawLine(Offset(size.width, r), Offset(size.width, r + len), paint);
    canvas.drawArc(Rect.fromLTWH(size.width - r * 2, 0, r * 2, r * 2),
        -3.14159 / 2, 3.14159 / 2, false, paint);

    // Bottom-left
    canvas.drawLine(
        Offset(r, size.height), Offset(r + len, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height - r), Offset(0, size.height - r - len), paint);
    canvas.drawArc(Rect.fromLTWH(0, size.height - r * 2, r * 2, r * 2),
        3.14159 / 2, 3.14159 / 2, false, paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - r, size.height),
        Offset(size.width - r - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - r),
        Offset(size.width, size.height - r - len), paint);
    canvas.drawArc(
        Rect.fromLTWH(size.width - r * 2, size.height - r * 2, r * 2, r * 2),
        0,
        3.14159 / 2,
        false,
        paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.opacity != opacity;
}
