import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const int kMaxPhotos = 4;

class DamagePhotosNotifier extends StateNotifier<List<String>> {
  DamagePhotosNotifier() : super([]);

  final _picker = ImagePicker();
  final _storage = Supabase.instance.client.storage;

  Future<void> pickAndUpload(String userId, String rentalId) async {
    if (state.length >= kMaxPhotos) return;

    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final fileName =
        '$userId/$rentalId/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _storage.from('damage-photos').upload(fileName, file);
    final url = _storage.from('damage-photos').getPublicUrl(fileName);

    state = [...state, url];
  }

  void removePhoto(int index) {
    final updated = [...state];
    updated.removeAt(index);
    state = updated;
  }

  Future<void> saveReport(String rentalId, String type) async {
    await Supabase.instance.client.from('damage_reports').insert({
      'rental_id': rentalId,
      'type': type, // 'before' or 'after'
      'photo_urls': state,
    });
    state = [];
  }
}

final damagePhotosProvider =
    StateNotifierProvider<DamagePhotosNotifier, List<String>>(
  (_) => DamagePhotosNotifier(),
);
