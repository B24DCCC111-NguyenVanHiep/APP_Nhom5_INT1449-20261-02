// FILE NÀY ĐỂ LÀM GÌ: Mô tả một tài khoản người dùng (chỉ cần khi vào màn Thử thách).
// Người phụ trách: Người 3 (phần mở rộng ngoài phân công)

/// Tài khoản. KHÔNG chứa mật khẩu (mật khẩu chỉ tồn tại dưới dạng băm trong kho lưu).
class UserAccount {
  const UserAccount({
    required this.id,
    required this.displayName,
    required this.email,
    required this.createdAt,
    this.walletAddress,
  });

  final String id;
  final String displayName;
  final String email;
  final DateTime createdAt;

  /// Để dành cho blockchain (ví thử nghiệm, chỉ tiền ảo). Hiện luôn null.
  final String? walletAddress;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
        'walletAddress': walletAddress,
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        email: json['email'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        walletAddress: json['walletAddress'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is UserAccount &&
      other.id == id &&
      other.displayName == displayName &&
      other.email == email &&
      other.createdAt == createdAt &&
      other.walletAddress == walletAddress;

  @override
  int get hashCode => Object.hash(id, displayName, email, createdAt, walletAddress);
}
