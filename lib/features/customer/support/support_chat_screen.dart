// lib/features/customer/support/support_chat_screen.dart
import 'package:flutter/material.dart';

class SupportChatScreen extends StatelessWidget {
  final String rentalId;
  const SupportChatScreen({super.key, required this.rentalId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Support Chat — rental $rentalId')));
}