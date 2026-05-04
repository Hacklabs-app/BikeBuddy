import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_dashboard.dart' show adminShopProvider;

// ─── Constants ────────────────────────────────────────────────────────────────

const _bgDark = Color(0xFF0F1117);
const _surface = Color(0xFF1A1D27);
const _surfaceAlt = Color(0xFF21242F);
const _green = Color(0xFF00C853);
const _red = Color(0xFFFF3D3D);
const _textPrimary = Color(0xFFEEF0F4);
const _textSecondary = Color(0xFF8B90A0);
const _border = Color(0xFF2A2D3A);

// ─── Screen ───────────────────────────────────────────────────────────────────

class ShopSetupScreen extends ConsumerStatefulWidget {
  const ShopSetupScreen({super.key});

  @override
  ConsumerState<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends ConsumerState<ShopSetupScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _bikesCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();

  bool _initialising = true;
  bool _saving = false;
  String? _error;

  // Non-null when editing an existing shop
  String? _shopId;
  String? _rateId;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _bikesCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────────

  Future<void> _loadExisting() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _initialising = false);
      return;
    }

    try {
      final shop = await _supabase
          .from('shops')
          .select()
          .eq('owner_id', uid)
          .maybeSingle();

      if (shop != null) {
        _shopId = shop['id'] as String;
        _nameCtrl.text = shop['name'] as String? ?? '';
        _addressCtrl.text = shop['address'] as String? ?? '';
        _bikesCtrl.text = (shop['total_bikes'] as int? ?? 0).toString();

        final rate = await _supabase
            .from('shop_rates')
            .select()
            .eq('shop_id', _shopId!)
            .maybeSingle();

        if (rate != null) {
          _rateId = rate['id'] as String;
          _rateCtrl.text = (rate['rate_per_hour'] as int? ?? 0).toString();
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _initialising = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final uid = _supabase.auth.currentUser!.id;
      final name = _nameCtrl.text.trim();
      final address = _addressCtrl.text.trim();
      final totalBikes = int.parse(_bikesCtrl.text.trim());
      final ratePerHour = int.parse(_rateCtrl.text.trim());

      if (_shopId == null) {
        // ── Create ──────────────────────────────────────────────────────────
        final shop = await _supabase.from('shops').insert({
          'owner_id': uid,
          'name': name,
          'address': address,
          'total_bikes': totalBikes,
        }).select().single();

        await _supabase.from('shop_rates').insert({
          'shop_id': shop['id'] as String,
          'rate_per_hour': ratePerHour,
        });
      } else {
        // ── Update ──────────────────────────────────────────────────────────
        await _supabase.from('shops').update({
          'name': name,
          'address': address,
          'total_bikes': totalBikes,
        }).eq('id', _shopId!);

        await _supabase.from('shop_rates').upsert({
          if (_rateId != null) 'id': _rateId,
          'shop_id': _shopId!,
          'rate_per_hour': ratePerHour,
        });
      }

      // Invalidate the dashboard's shop cache so it reloads fresh data.
      ref.invalidate(adminShopProvider);

      if (mounted) context.go('/admin');
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  bool get _isEdit => _shopId != null;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bgDark,
        body: _initialising
            ? const Center(child: CircularProgressIndicator(color: _green))
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildForm(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _green.withValues(alpha: 0.25)),
          ),
          child: const Icon(Icons.store_outlined, color: _green, size: 28),
        ),
        const SizedBox(height: 20),
        Text(
          _isEdit ? 'Edit Shop' : 'Set Up Your Shop',
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isEdit
              ? 'Update your shop details and pricing.'
              : 'You\'re one step away from accepting your first booking.',
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(
              label: 'Shop Name',
              hint: 'e.g. Nairobi Bike Hub',
              controller: _nameCtrl,
              icon: Icons.storefront_outlined,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Shop name is required' : null,
            ),
            const SizedBox(height: 20),
            _field(
              label: 'Address',
              hint: 'e.g. Kenyatta Ave, Nairobi CBD',
              controller: _addressCtrl,
              icon: Icons.location_on_outlined,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Address is required' : null,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _field(
                    label: 'Total Bikes',
                    hint: 'e.g. 10',
                    controller: _bikesCtrl,
                    icon: Icons.pedal_bike_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Required';
                      }
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 0) return 'Must be 0 or more';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _field(
                    label: 'Hourly Rate (KES)',
                    hint: 'e.g. 200',
                    controller: _rateCtrl,
                    prefix: 'KES ',
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = int.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Must be greater than 0';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _red.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: _red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: _red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        _isEdit ? 'Save Changes' : 'Create Shop',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

            if (_isEdit) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: _saving ? null : () => context.go('/admin'),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: _textSecondary, fontSize: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    String? prefix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(color: _textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, color: _textSecondary, size: 18),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            prefixText: prefix,
            prefixStyle: const TextStyle(
              color: _textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: _surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _red, width: 1.5),
            ),
            errorStyle: const TextStyle(color: _red, fontSize: 11),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}
