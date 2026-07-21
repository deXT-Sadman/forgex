/// User data model mirroring a MongoDB "users" document:
/// {
///   "_id": "665a0b...",
///   "username": "sadman",
///   "email": "sadman@example.com",
///   "profileImageUrl": "https://.../avatar.jpg",
///   "createdAt": "..."
/// }
///
/// The password itself is never stored in this model on the client;
/// it is only ever sent over the wire during login/signup/reset calls.
class UserModel {
  final String? id;
  final String username;
  final String email;
  final String? profileImageUrl; // remote URL once uploaded
  final String? localProfileImagePath; // local file path (offline fallback)
  final DateTime? createdAt;

  UserModel({
    this.id,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.localProfileImagePath,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString(),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      localProfileImagePath: json['localProfileImagePath'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'localProfileImagePath': localProfileImagePath,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? profileImageUrl,
    String? localProfileImagePath,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      localProfileImagePath:
          localProfileImagePath ?? this.localProfileImagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
