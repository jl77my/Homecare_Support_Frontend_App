class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? token;

  // 5 Mandatory Audit Columns
  final String? createdBy;
  final DateTime? datetimeCreated;
  final String? updatedBy;
  final DateTime? datetimeUpdated;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
    this.createdBy,
    this.datetimeCreated,
    this.updatedBy,
    this.datetimeUpdated,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: '${json['Id'] ?? json['id'] ?? json['uid'] ?? ''}',
      name: '${json['Name'] ?? json['name'] ?? json['FullName'] ?? ''}',
      email: '${json['Email'] ?? json['email'] ?? ''}',
      role: '${json['Role'] ?? json['role'] ?? 'family'}',
      token: json['token']?.toString(),
      createdBy: json['CreatedBy']?.toString(),
      datetimeCreated: json['DatetimeCreated'] != null
          ? DateTime.tryParse(json['DatetimeCreated'])
          : null,
      updatedBy: json['UpdatedBy']?.toString(),
      datetimeUpdated: json['DatetimeUpdated'] != null
          ? DateTime.tryParse(json['DatetimeUpdated'])
          : null,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? token,
    String? createdBy,
    DateTime? datetimeCreated,
    String? updatedBy,
    DateTime? datetimeUpdated,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      token: token ?? this.token,
      createdBy: createdBy ?? this.createdBy,
      datetimeCreated: datetimeCreated ?? this.datetimeCreated,
      updatedBy: updatedBy ?? this.updatedBy,
      datetimeUpdated: datetimeUpdated ?? this.datetimeUpdated,
    );
  }
}