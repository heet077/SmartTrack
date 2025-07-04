import 'dart:convert';
import 'package:crypto/crypto.dart';

class Instructor {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final List<String> programIds;  // For managing multiple programs
  final String username;
  final DateTime? last_login;
  final String password;

  Instructor({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role = 'instructor',
    this.programIds = const [],  // Default to empty list
    required this.username,
    this.last_login,
    required this.password,
  });

  // Convert Instructor to Map for the main instructors table
  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'username': username,
      'last_login': last_login?.toIso8601String(),
      'password': password,
    };
  }

  // Create program mappings for the join table
  List<Map<String, dynamic>> createProgramMappings() {
    return programIds.map((programId) => {
      'instructor_id': id,
      'program_id': programId,
    }).toList();
  }

  // Create Instructor from Map
  factory Instructor.fromMap(Map<String, dynamic> map, {List<String>? programIds}) {
    return Instructor(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      role: map['role'] ?? 'instructor',
      programIds: programIds ?? [],
      username: map['username'] ?? map['email'] ?? '',
      last_login: map['last_login'] != null ? DateTime.parse(map['last_login']) : null,
      password: map['password'] ?? '',
    );
  }

  // Create a copy of Instructor with some fields updated
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
  }) {
    return Instructor(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      programIds: programIds ?? this.programIds,
      username: username ?? this.username,
      last_login: last_login ?? this.last_login,
      password: password ?? this.password,
    );
  }
} 