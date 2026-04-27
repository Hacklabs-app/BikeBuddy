import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _green = Color(0xFF00C853);
const _greenLight = Color(0xFF69F0AE);
const _amber = Color(0xFFFFB300);
const _textDark = Color(0xFF0D1F0F);
const _textMid = Color(0xFF4A5E4C);
const _textLight = Color(0xFF8FA891);
const _border = Color(0xFFDDE8DF);
const _bg = Color(0xFFF7F9F5);

class BookingConfirmScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> bike;
  final int selectedHours;

  const BookingConfirmScreen({
    super.key,
    required this.bike,
    required this.selectedHours,
  });

  @override
  ConsumerState<BookingConfirmScreen> createState() =>
      _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends ConsumerState<BookingConfirmScreen>
    with TickerProviderStateMixin {
  bool _loading = false;
  bool _confirmed = false;
  late AnimationController _successCtrl;
  late AnimationController _enterCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _checkAnim;
  int _hours = 1;

  @override
  void initState() {
    super.initState();
    _hours = widget.selectedHours;
    _enterCtrl = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this)
      ..forward();
    _successCtrl = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
    _checkAnim = CurvedAnimation(parent: _successCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  double get _totalCost =>
      (widget.bike['hourly_rate'] as num).toDouble() * _hours;

  Future<void> _confirmBooking() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      context.push('/login');
      return;
    }
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      await supabase.from('rentals').insert({
        'bike_id': widget.bike['id'],
        'customer_id': user.id,
        'shop_id': widget.bike['shop_id'],
        'checkout_time': now.toIso8601String(),
        'expected_return': now.add(Duration(hours: _hours)).toIso8601String(),
        'hourly_rate': widget.bike['hourly_rate'],
        'status': 'reserved',
        'hold_expiry': now.add(const Duration(minutes: 15)).toIso8601String(),
      });
      await supabase
          .from('bikes')
          .update({'status': 'reserved'}).eq('id', widget.bike['id'] as String);
      setState(() => _confirmed = true);
      _successCtrl.forward();
      HapticFeedback.heavyImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Booking failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bike = widget.bike;
    final bikeName = bike['name'] as String? ?? 'Bike';
    final type = bike['type'] as String? ?? 'standard';
    final shopName =
        (bike['shops'] as Map?)?['name'] as String? ?? 'Unknown Shop';
    final shopLocation = (bike['shops'] as Map?)?['location'] as String? ?? '';
    final rate = (bike['hourly_rate'] as num).toDouble();

    final typeColor = switch (type) {
      'electric' => const Color(0xFF2979FF),
      'mountainBike' => const Color(0xFFFF6D00),
      'city' => const Color(0xFF9C27B0),
      _ => _green,
    };
    final typeIcon = switch (type) {
      'electric' => Icons.electric_bike,
      'mountainBike' => Icons.terrain,
      'city' => Icons.location_city,
      _ => Icons.pedal_bike,
    };

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : _textDark, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _confirmed ? 'Booking Confirmed' : 'Confirm Booking',
          style: TextStyle(
              color: isDark ? Colors.white : _textDark,
              fontWeight: FontWeight.w800,
              fontSize: 18),
        ),
      ),
      body: _confirmed
          ? _buildSuccess(isDark, bikeName)
          : _buildForm(isDark, bikeName, shopName, shopLocation, rate,
              typeColor, typeIcon),
    );
  }

  Widget _buildSuccess(bool isDark, String bikeName) {
    return FadeTransition(
      opacity: _checkAnim,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_green, _greenLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: _green.withValues(alpha: 0.35),
                        blurRadius: 32,
                        offset: const Offset(0, 12))
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 60),
              ),
            ),
            const SizedBox(height: 32),
            Text("You're all set! 🎉",
                style: TextStyle(
                    color: isDark ? Colors.white : _textDark,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8)),
            const SizedBox(height: 12),
            Text(
              'Your bike is reserved for 15 minutes.\nHead to the shop and scan the QR code to start.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isDark ? Colors.white60 : _textLight,
                  fontSize: 15,
                  height: 1.6),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C2128) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _green.withValues(alpha: 0.3)),
              ),
              child: Column(children: [
                _confirmRow(Icons.pedal_bike, 'Bike', bikeName, isDark),
                const SizedBox(height: 12),
                _confirmRow(Icons.access_time, 'Duration',
                    '$_hours hour${_hours > 1 ? 's' : ''}', isDark),
                const SizedBox(height: 12),
                _confirmRow(Icons.attach_money, 'Estimated Cost',
                    '\$${_totalCost.toStringAsFixed(2)}', isDark),
                const SizedBox(height: 12),
                _confirmRow(Icons.timer_outlined, 'Hold Expires In',
                    '15 minutes', isDark),
              ]),
            ),
            const SizedBox(height: 32),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/home'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: _border, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Back to Home',
                      style: TextStyle(
                          color: isDark ? Colors.white70 : _textMid,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/scan'),
                  icon: const Icon(Icons.qr_code_scanner,
                      color: Colors.white, size: 18),
                  label: const Text('Scan to Ride',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _confirmRow(IconData icon, String label, String value, bool isDark) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: _green, size: 16),
      ),
      const SizedBox(width: 12),
      Text(label,
          style: TextStyle(
              color: isDark ? Colors.white60 : _textLight, fontSize: 13)),
      const Spacer(),
      Text(value,
          style: TextStyle(
              color: isDark ? Colors.white : _textDark,
              fontSize: 14,
              fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _buildForm(bool isDark, String bikeName, String shopName,
      String shopLocation, double rate, Color typeColor, IconData typeIcon) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Bike card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                typeColor.withValues(alpha: 0.15),
                typeColor.withValues(alpha: 0.05)
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: typeColor.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18)),
                child: Icon(typeIcon, color: typeColor, size: 38),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bikeName,
                          style: TextStyle(
                              color: isDark ? Colors.white : _textDark,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text(shopName,
                          style: TextStyle(
                              color: isDark ? Colors.white60 : _textMid,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      if (shopLocation.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(children: [
                          Icon(Icons.location_on,
                              size: 12,
                              color: isDark ? Colors.white38 : _textLight),
                          const SizedBox(width: 2),
                          Text(shopLocation,
                              style: TextStyle(
                                  color: isDark ? Colors.white38 : _textLight,
                                  fontSize: 12)),
                        ]),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: typeColor,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text('\$${rate.toStringAsFixed(0)}/hr',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                      ),
                    ]),
              ),
            ]),
          ),
          const SizedBox(height: 28),

          // Duration
          Text('Select Duration',
              style: TextStyle(
                  color: isDark ? Colors.white : _textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Row(
            children: [1, 2, 3, 4, 6, 8].map((h) {
              final sel = _hours == h;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _hours = h),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: sel
                          ? _green
                          : isDark
                              ? const Color(0xFF1C2128)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel ? _green : _border, width: sel ? 0 : 1.5),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                  color: _green.withValues(alpha: 0.3),
                                  blurRadius: 10)
                            ]
                          : [],
                    ),
                    child: Column(children: [
                      Text('${h}h',
                          style: TextStyle(
                              color: sel
                                  ? Colors.white
                                  : isDark
                                      ? Colors.white70
                                      : _textDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                      Text('\$${(rate * h).toStringAsFixed(0)}',
                          style: TextStyle(
                              color: sel ? Colors.white70 : _textLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: _amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _amber.withValues(alpha: 0.25))),
            child: Row(children: [
              const Icon(Icons.info_outline, color: _amber, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bike held for 15 min after booking. Scan QR at the shop to start your ride.',
                  style: TextStyle(
                      color: isDark ? Colors.white70 : _textMid,
                      fontSize: 12,
                      height: 1.5),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Cost breakdown
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C2128) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border)),
            child: Column(children: [
              _costRow(
                  'Rate', '\$${rate.toStringAsFixed(2)}/hr', isDark, false),
              const SizedBox(height: 10),
              _costRow('Duration', '$_hours hour${_hours > 1 ? 's' : ''}',
                  isDark, false),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: _border)),
              _costRow('Estimated Total', '\$${_totalCost.toStringAsFixed(2)}',
                  isDark, true),
              const SizedBox(height: 6),
              const Text(
                'Final cost rounded to nearest 15-min block on return',
                style: TextStyle(color: _textLight, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
          const SizedBox(height: 28),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _confirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text('Confirm — \$${_totalCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text('Pay at the shop on return',
                style: TextStyle(color: _textLight, fontSize: 12)),
          ),
        ]),
      ),
    );
  }

  Widget _costRow(String label, String value, bool isDark, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: isTotal
                    ? (isDark ? Colors.white : _textDark)
                    : (isDark ? Colors.white60 : _textLight),
                fontSize: isTotal ? 15 : 13,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                color: isTotal ? _green : (isDark ? Colors.white : _textDark),
                fontSize: isTotal ? 20 : 14,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}
