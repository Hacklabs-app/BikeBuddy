enum BikeType { electric, mountainBike, city, standard }
enum BikeStatus { available, rented, reserved, maintenance }

class BikeModel {
  final String id;
  final String shopId;
  final String name;
  final BikeType type;
  final BikeStatus status;
  final double hourlyRate;
  final String? qrCode;
  final String? imageUrl;
  final DateTime? lastServiced;
  final String? notes;

  const BikeModel({
    required this.id,
    required this.shopId,
    required this.name,
    required this.type,
    required this.status,
    required this.hourlyRate,
    this.qrCode,
    this.imageUrl,
    this.lastServiced,
    this.notes,
  });

  factory BikeModel.fromMap(Map<String, dynamic> map) {
    return BikeModel(
      id: map['id'] as String,
      shopId: map['shop_id'] as String,
      name: map['name'] as String,
      type: BikeType.values.byName(map['type'] as String),
      status: BikeStatus.values.byName(map['status'] as String),
      hourlyRate: (map['hourly_rate'] as num).toDouble(),
      qrCode: map['qr_code'] as String?,
      imageUrl: map['image_url'] as String?,
      lastServiced: map['last_serviced'] != null
          ? DateTime.parse(map['last_serviced'] as String)
          : null,
      notes: map['notes'] as String?,
    );
  }

  // Available count helper used across the app
  bool get isAvailable => status == BikeStatus.available;
}