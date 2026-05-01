// lib/features/customer/booking/reservation_screen.dart
import 'package:flutter/material.dart';

class ReservationScreen extends StatelessWidget {
  final String bikeId;
  const ReservationScreen({super.key, required this.bikeId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Reserve bike $bikeId')));
}
