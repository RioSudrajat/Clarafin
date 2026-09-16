class AuthUserModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final String avatarUrl;

  const AuthUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.avatarUrl = 'assets/images/avatars/avatar_1.png',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'avatarUrl': avatarUrl,
      };

  factory AuthUserModel.fromJson(Map<String, dynamic> json) => AuthUserModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        password: json['password'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String? ?? 'assets/images/avatars/avatar_1.png',
      );
}
