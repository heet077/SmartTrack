class User {
  final String id;
  final String email;
  final String role;
  final String? name;
  final String? profileImage;

  User({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.profileImage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'name': name,
      'profile_image': profileImage,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      name: map['name'],
      profileImage: map['profile_image'],
    );
  }
} 