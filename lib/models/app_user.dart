// FILE NÀY ĐỂ LÀM GÌ: Mô tả thông tin người dùng trong ứng dụng.
// Người phụ trách: Người 2 (Database)

/// Thông tin người dùng
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.isGuest = false,
  });

  final String id;
  final String name;
  final String email;
  final bool isGuest;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'isGuest': isGuest,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String? ?? 'guest_id',
        name: json['name'] as String? ?? 'Khách',
        email: json['email'] as String? ?? '',
        isGuest: json['isGuest'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.name == name &&
      other.email == email &&
      other.isGuest == isGuest;

  @override
  int get hashCode => Object.hash(id, name, email, isGuest);

  @override
  String toString() =>
      'AppUser(id: $id, name: $name, email: $email, isGuest: $isGuest)';
}
