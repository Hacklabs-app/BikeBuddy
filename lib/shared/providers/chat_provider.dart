import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderRole; // 'customer' | 'shop'
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    id: map['id'],
    senderId: map['sender_id'],
    senderRole: map['sender_role'],
    content: map['content'],
    createdAt: DateTime.parse(map['created_at']),
  );
}

// Stream of messages for a given rental
final chatStreamProvider = StreamProvider.family<List<ChatMessage>, String>(
  (ref, rentalId) {
    return Supabase.instance.client
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('rental_id', rentalId)
      .order('created_at')
      .map((rows) => rows.map(ChatMessage.fromMap).toList());
  },
);

// Send a message
Future<void> sendMessage({
  required String rentalId,
  required String senderId,
  required String senderRole,
  required String content,
}) async {
  await Supabase.instance.client.from('messages').insert({
    'rental_id': rentalId,
    'sender_id': senderId,
    'sender_role': senderRole,
    'content': content,
  });
}