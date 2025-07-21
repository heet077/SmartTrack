import 'dart:convert';
import 'package:crypto/crypto.dart';

class Instructor {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final List<String> programIds;
  final String username;
  final DateTime? last_login;
  final String password;
  final String? short_name;

  Instructor({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role = 'instructor',
    this.programIds = const [],
    String? username,
    this.last_login,
    required this.password,
    this.short_name,
  }) : username = username ?? email;

  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'email': email,
      'role': role,
      'username': username,
      'password': password,
    };

    if (id.isNotEmpty) map['id'] = id;
    if (phone != null) map['phone'] = phone!;
    if (last_login != null) map['last_login'] = last_login!.toIso8601String();
    if (short_name != null) map['short_name'] = short_name!;

    return map;
  }

  List<Map<String, dynamic>> createProgramMappings() {
    return programIds.map((programId) => {
      'instructor_id': id,
      'program_id': programId,
    }).toList();
  }

  factory Instructor.fromMap(Map<String, dynamic> map, {List<String>? programIds}) {
    return Instructor(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: map['phone']?.toString(),
      role: (map['role'] ?? 'instructor').toString(),
      programIds: programIds ?? [],
      username: map['username']?.toString(),
      last_login: map['last_login'] != null ? DateTime.parse(map['last_login'].toString()) : null,
      password: (map['password'] ?? '').toString(),
      short_name: map['short_name']?.toString(),
    );
  }

  Instructor copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    List<String>? programIds,
    String? username,
    DateTime? last_login,
    String? password,
    String? short_name,
  }) {
    return Instructor(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      programIds: programIds ?? this.programIds,
      username: username,
      last_login: last_login ?? this.last_login,
      password: password ?? this.password,
      short_name: short_name ?? this.short_name,
    );
  }
} 