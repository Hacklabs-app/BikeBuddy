// lib/features/customer/ride/damage_photo_screen.dart
import 'package:flutter/material.dart';

class DamagePhotoScreen extends StatelessWidget {
  final String rentalId;
  final String type; // 'before' | 'after'
  const DamagePhotoScreen(
      {super.key, required this.rentalId, required this.type});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Damage Photos — $type')));
}
