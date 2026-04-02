class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? token;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: '${json['id'] ?? json['_id'] ?? ''}',
      name: '${json['name'] ?? json['fullName'] ?? ''}',
      email: '${json['email'] ?? ''}',
      role: '${json['role'] ?? 'family'}',
      token: json['token']?.toString(),
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      token: token ?? this.token,
    );
  }
}