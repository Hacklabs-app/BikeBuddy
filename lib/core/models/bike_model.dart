class BikeModel {
  final String id;
  final String shopId;
  final String name;
  final String type;
  final String status;
  final double hourlyRate;

  const BikeModel({
    required this.id,
    required this.shopId,
    required this.name,
    required this.type,
    required this.status,
    required this.hourlyRate,
  });

  factory BikeModel.fromMap(Map<String, dynamic> map) {
    return BikeModel(
      id: map['id'] as String,
      shopId: map['shop_id'] as String,
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'standard',
      status: map['status'] as String? ?? 'available',
      hourlyRate: (map['hourly_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'shop_id': shopId,
        'name': name,
        'type': type,
        'status': status,
        'hourly_rate': hourlyRate,
      };
}
