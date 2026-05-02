enum UserRole { owner, customer }

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? shopId;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.shopId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String,
      role: map['role'] == 'owner' ? UserRole.owner : UserRole.customer,
      shopId: map['shop_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role.name,
        'shop_id': shopId,
      };
}
