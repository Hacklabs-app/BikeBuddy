import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _green = Color(0xFF00C853);
const _greenLight = Color(0xFF69F0AE);
const _amber = Color(0xFFFFB300);
const _red = Color(0xFFFF3D3D);
const _textDark = Color(0xFF0D1F0F);
const _textLight = Color(0xFF8FA891);
const _border = Color(0xFFDDE8DF);
const _bg = Color(0xFFF7F9F5);

// ─── Billing Calculator ───────────────────────────────────────────────────────
double calculateBill(DateTime checkout, DateTime checkin, double hourlyRate) {
  final rawMins = checkin.difference(checkout).inMinutes;
  final roundedMins = ((rawMins / 15).ceil() * 15).clamp(15, 99999);
  return double.parse(((roundedMins / 60) * hourlyRate).toStringAsFixed(2));
}

// ─── Active Rental Provider ───────────────────────────────────────────────────
final activeRentalProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  final data = await supabase
      .from('rentals')
      .select('*, bikes(name, type, hourly_rate, shops(name, location))')
      .eq('customer_id', user.id)
      .inFilter('status', ['active', 'reserved'])
      .order('checkout_time', ascending: false)
      .limit(1)
      .maybeSingle();

  return data;
});

// ─── Screen ───────────────────────────────────────────────────────────────────
class ActiveRideScreen extends ConsumerStatefulWidget {
  const ActiveRideScreen({super.key});

  @override
  ConsumerState<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends ConsumerState<ActiveRideScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  DateTime? _checkoutTime;
  bool _checkingIn = false;
  bool _checkedIn = false;
  double? _finalBill;

  late AnimationController _pulseCtrl;
  late AnimationController _successCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(duration: const Duration(seconds: 2), vsync: this)
          ..repeat(reverse: true);
    _successCtrl = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
  }

  void _startTimer(DateTime checkout) {
    _checkoutTime = checkout;
    _elapsed = DateTime.now().difference(checkout);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed = DateTime.now().difference(_checkoutTime!));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final h = _elapsed.inHours.toString().padLeft(2, '0');
    final m = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  double _currentCost(double hourlyRate) {
    if (_checkoutTime == null) return 0;
    return calculateBill(_checkoutTime!, DateTime.now(), hourlyRate);
  }

  Future<void> _checkIn(Map<String, dynamic> rental) async {
    setState(() => _checkingIn = true);
    final supabase = Supabase.instance.client;

    try {
      final now = DateTime.now();
      final checkout = DateTime.parse(rental['checkout_time'] as String);
      final rate = (rental['bikes']['hourly_rate'] as num).toDouble();
      final bill = calculateBill(checkout, now, rate);

      await supabase.from('rentals').update({
        'checkin_time': now.toIso8601String(),
        'total_cost': bill,
        'status': 'completed',
      }).eq('id', rental['id'] as String);

      await supabase.from('bikes').update({'status': 'available'}).eq(
          'id', rental['bike_id'] as String);

      setState(() {
        _checkedIn = true;
        _finalBill = bill;
      });
      _timer?.cancel();
      _successCtrl.forward();
      HapticFeedback.heavyImpact();
      ref.invalidate(activeRentalProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Check-in failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rentalAsync = ref.watch(activeRentalProvider);

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
        title: Text('Active Ride',
            style: TextStyle(
                color: isDark ? Colors.white : _textDark,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
      ),
      body: rentalAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _green)),
        error: (e, _) => Center(
            child:
                Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (rental) {
          if (rental == null) return _buildNoActiveRide(isDark);

          // Start timer if not started
          if (_checkoutTime == null && !_checkedIn) {
            final checkout = DateTime.parse(rental['checkout_time'] as String);
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _startTimer(checkout));
          }

          if (_checkedIn && _finalBill != null) {
            return _buildCheckInSuccess(isDark, rental);
          }

          return _buildActiveRide(isDark, rental);
        },
      ),
    );
  }

  // ── No Active Ride ──────────────────────────────────────────────────────────

  Widget _buildNoActiveRide(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.1), shape: BoxShape.circle),
            child:
                const Icon(Icons.pedal_bike_outlined, color: _green, size: 50),
          ),
          const SizedBox(height: 24),
          Text('No Active Ride',
              style: TextStyle(
                  color: isDark ? Colors.white : _textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text("You don't have a bike out right now.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isDark ? Colors.white54 : _textLight,
                  fontSize: 14,
                  height: 1.5)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.search, color: Colors.white),
            label: const Text('Find a Bike',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
          ),
        ]),
      ),
    );
  }

  // ── Active Ride UI ──────────────────────────────────────────────────────────

  Widget _buildActiveRide(bool isDark, Map<String, dynamic> rental) {
    final bike = rental['bikes'] as Map<String, dynamic>;
    final bikeName = bike['name'] as String? ?? 'Bike';
    final type = bike['type'] as String? ?? 'standard';
    final rate = (bike['hourly_rate'] as num).toDouble();
    final shopName = (bike['shops'] as Map?)?['name'] as String? ?? 'Shop';
    final shopLocation = (bike['shops'] as Map?)?['location'] as String? ?? '';
    final expectedReturn = rental['expected_return'] != null
        ? DateTime.parse(rental['expected_return'] as String)
        : null;
    final isLate =
        expectedReturn != null && DateTime.now().isAfter(expectedReturn);
    final status = rental['status'] as String;

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        // Timer hero
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: isLate ? 1.0 : _pulseAnim.value * 0.02 + 0.98,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLate
                      ? [_red, const Color(0xFFB71C1C)]
                      : [_green, const Color(0xFF004D20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: (isLate ? _red : _green).withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(typeIcon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(bikeName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 24),
                if (isLate)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('⚠ LATE RETURN',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.5)),
                  ),
                const SizedBox(height: 12),
                Text(
                  status == 'reserved' ? 'HOLD ACTIVE' : _formattedTime,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: status == 'reserved' ? 28 : 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: status == 'reserved' ? 2 : -2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  status == 'reserved'
                      ? 'Scan QR code at the shop to start'
                      : 'Time on ride',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Live cost
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2128) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Running Cost',
                        style: TextStyle(
                            color: isDark ? Colors.white54 : _textLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '\$${_currentCost(rate).toStringAsFixed(2)}',
                      style: TextStyle(
                          color: isLate ? _red : _green,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1),
                    ),
                    Text('\$${rate.toStringAsFixed(2)}/hr',
                        style: TextStyle(
                            color: isDark ? Colors.white38 : _textLight,
                            fontSize: 12)),
                  ]),
            ),
            Container(
              width: 1,
              height: 60,
              color: _border,
              margin: const EdgeInsets.symmetric(horizontal: 20),
            ),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shop',
                        style: TextStyle(
                            color: isDark ? Colors.white54 : _textLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(shopName,
                        style: TextStyle(
                            color: isDark ? Colors.white : _textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    if (shopLocation.isNotEmpty)
                      Text(shopLocation,
                          style: TextStyle(
                              color: isDark ? Colors.white38 : _textLight,
                              fontSize: 12)),
                  ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Expected return
        if (expectedReturn != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLate
                  ? _red.withValues(alpha: 0.08)
                  : _amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isLate
                      ? _red.withValues(alpha: 0.3)
                      : _amber.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Icon(isLate ? Icons.warning_amber : Icons.schedule,
                  color: isLate ? _red : _amber, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isLate
                      ? 'You were expected back at ${_formatTime(expectedReturn)}. Extra charges apply.'
                      : 'Expected return by ${_formatTime(expectedReturn)}',
                  style: TextStyle(
                      color:
                          isLate ? _red : (isDark ? Colors.white70 : _textDark),
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: isLate ? FontWeight.w600 : FontWeight.normal),
                ),
              ),
            ]),
          ),
        const SizedBox(height: 24),

        // Billing note
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C2128) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border)),
          child: Row(children: [
            Icon(Icons.info_outline,
                color: isDark ? Colors.white38 : _textLight, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Final bill rounded to nearest 15-minute block. Minimum charge: 15 minutes.',
                style: TextStyle(
                    color: isDark ? Colors.white54 : _textLight,
                    fontSize: 12,
                    height: 1.5),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 32),

        // Check-in button
        if (status == 'active') ...[
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed:
                  _checkingIn ? null : () => _showCheckInConfirm(rental, rate),
              icon: _checkingIn
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.flag_rounded,
                      color: Colors.white, size: 22),
              label: Text(
                _checkingIn
                    ? 'Processing...'
                    : 'Return Bike — \$${_currentCost(rate).toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLate ? _red : _green,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text('Tap when you\'ve returned the bike to the shop',
                style: TextStyle(color: _textLight, fontSize: 12)),
          ),
        ] else ...[
          // Reserved — show scan prompt
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/scan'),
              icon: const Icon(Icons.qr_code_scanner,
                  color: Colors.white, size: 22),
              label: const Text('Scan QR to Start Ride',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
            ),
          ),
        ],
      ]),
    );
  }

  void _showCheckInConfirm(Map<String, dynamic> rental, double rate) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bill = _currentCost(rate);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2128) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: _border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Icon(Icons.flag_rounded, color: _green, size: 40),
          const SizedBox(height: 16),
          Text('Return Bike?',
              style: TextStyle(
                  color: isDark ? Colors.white : _textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'Your total will be \$${bill.toStringAsFixed(2)} for ${_elapsed.inMinutes} minutes.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isDark ? Colors.white60 : _textLight,
                fontSize: 14,
                height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: _border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text('Keep Riding',
                    style: TextStyle(
                        color: isDark ? Colors.white70 : _textDark,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _checkIn(rental);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Yes, Return',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // ── Check-in Success ────────────────────────────────────────────────────────

  Widget _buildCheckInSuccess(bool isDark, Map<String, dynamic> rental) {
    final bike = rental['bikes'] as Map<String, dynamic>;
    final bikeName = bike['name'] as String? ?? 'Bike';
    final duration = _elapsed;
    final h = duration.inHours;
    final m = duration.inMinutes % 60;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
            child:
                const Icon(Icons.check_rounded, color: Colors.white, size: 60),
          ),
        ),
        const SizedBox(height: 32),
        Text('Ride Complete! 🏁',
            style: TextStyle(
                color: isDark ? Colors.white : _textDark,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8)),
        const SizedBox(height: 12),
        Text('Thanks for riding with Bike Buddy',
            style: TextStyle(
                color: isDark ? Colors.white54 : _textLight, fontSize: 14)),
        const SizedBox(height: 32),

        // Bill summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2128) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _green.withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            const Text('RECEIPT',
                style: TextStyle(
                    color: _textLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5)),
            const SizedBox(height: 16),
            Text(bikeName,
                style: TextStyle(
                    color: isDark ? Colors.white : _textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            _receiptRow('Duration', '${h}h ${m}m', isDark),
            const SizedBox(height: 8),
            _receiptRow('Billing', 'Rounded to 15-min blocks', isDark),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: _border)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('TOTAL DUE',
                  style: TextStyle(
                      color: isDark ? Colors.white : _textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
              Text('\$${_finalBill!.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: _green,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1)),
            ]),
            const SizedBox(height: 8),
            const Text('Pay at the shop counter',
                style: TextStyle(color: _textLight, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 32),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.go('/history'),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: _border, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: Text('View History',
                  style: TextStyle(
                      color: isDark ? Colors.white70 : _textDark,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: const Text('Done',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _receiptRow(String label, String value, bool isDark) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(
              color: isDark ? Colors.white54 : _textLight, fontSize: 13)),
      Text(value,
          style: TextStyle(
              color: isDark ? Colors.white : _textDark,
              fontSize: 13,
              fontWeight: FontWeight.w600)),
    ]);
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $suffix';
  }
}
