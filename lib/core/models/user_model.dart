enum UserRole { owner, customer, pending }

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? shopId;
  final String? idNumber;
  final String? phoneNumber;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.shopId,
    this.idNumber,
    this.phoneNumber,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      role: _parseRole(map['role'] as String?),
      shopId: map['shop_id'] as String?,
      idNumber: map['id_number'] as String?,
      phoneNumber: map['phone_number'] as String?,
    );
  }

  static UserRole _parseRole(String? role) {
    if (role == 'owner') return UserRole.owner;
    if (role == 'customer') return UserRole.customer;
    return UserRole.pending;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role.name,
        'shop_id': shopId,
        'id_number': idNumber,
        'phone_number': phoneNumber,
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    String? shopId,
    String? idNumber,
    String? phoneNumber,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      shopId: shopId ?? this.shopId,
      idNumber: idNumber ?? this.idNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
